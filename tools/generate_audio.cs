using System;
using System.IO;

public static class GothicAudioGenerator
{
    private const int SampleRate = 22050;
    private const double Tau = Math.PI * 2.0;

    public static void Generate(string projectRoot)
    {
        string sfx = Path.Combine(projectRoot, "audio", "sfx");
        string bgm = Path.Combine(projectRoot, "audio", "bgm");
        Directory.CreateDirectory(sfx);
        Directory.CreateDirectory(bgm);
        WriteMusic(Path.Combine(bgm, "silent_forest_theme.wav"));
        WriteEffect(Path.Combine(sfx, "jump.wav"), "jump", 0.24);
        WriteEffect(Path.Combine(sfx, "dash.wav"), "dash", 0.34);
        WriteEffect(Path.Combine(sfx, "slash.wav"), "slash", 0.27);
        WriteEffect(Path.Combine(sfx, "spin.wav"), "spin", 0.48);
        WriteEffect(Path.Combine(sfx, "thrust.wav"), "thrust", 0.24);
        WriteEffect(Path.Combine(sfx, "hit.wav"), "hit", 0.20);
        WriteEffect(Path.Combine(sfx, "blood_blossom.wav"), "blood", 0.82);
        WriteEffect(Path.Combine(sfx, "execution.wav"), "execution", 0.95);
        WriteEffect(Path.Combine(sfx, "wolf_summon.wav"), "wolf", 0.90);
    }

    private static void WriteMusic(string path)
    {
        double bpm = 76.0;
        double beat = 60.0 / bpm;
        double bar = beat * 4.0;
        double duration = bar * 16.0;
        int length = (int)Math.Round(duration * SampleRate);
        double[] left = new double[length];
        double[] right = new double[length];
        double[] roots = { 220.00, 174.61, 146.83, 164.81 };
        double[] thirds = { 261.63, 220.00, 174.61, 207.65 };
        double[] fifths = { 329.63, 261.63, 220.00, 246.94 };
        double[] melody = { 440.00, 392.00, 329.63, 392.00, 523.25, 440.00, 392.00, 293.66 };
        for (int i = 0; i < length; i++)
        {
            double t = i / (double)SampleRate;
            int chord = ((int)(t / bar)) % 4;
            double barPosition = t % bar;
            double blend = Clamp((barPosition - (bar - 0.42)) / 0.42, 0.0, 1.0);
            double padA = Pad(t, roots[chord], thirds[chord], fifths[chord]);
            int next = (chord + 1) % 4;
            double padB = Pad(t, roots[next], thirds[next], fifths[next]);
            double pad = padA * (1.0 - blend) + padB * blend;

            double phase = t % beat;
            double pulse = Math.Exp(-phase * 7.0) * Math.Sin(Tau * (roots[chord] * 0.5) * phase);
            double eventLength = beat * 2.0;
            double eventPhase = t % eventLength;
            int eventIndex = (int)(t / eventLength);
            double bell = 0.0;
            if (eventPhase < 1.15)
            {
                double age = eventPhase;
                double f = melody[eventIndex % melody.Length];
                bell = (Math.Sin(Tau * f * age) + 0.28 * Math.Sin(Tau * f * 2.01 * age)) * Math.Exp(-age * 3.6);
            }
            double air = 0.008 * Math.Sin(Tau * 117.0 * t + 0.3 * Math.Sin(Tau * 0.11 * t));
            double fade = Math.Min(1.0, Math.Min(t / 0.20, (duration - t) / 0.20));
            double center = (0.45 * pad + 0.12 * pulse + 0.07 * bell + air) * fade;
            double width = 0.86 + 0.08 * Math.Sin(Tau * 0.07 * t);
            left[i] = center * width;
            right[i] = center * (1.72 - width) + 0.012 * bell * Math.Sin(Tau * 0.09 * t);
        }
        WriteWav(path, left, right, SampleRate);
    }

    private static double Pad(double t, double root, double third, double fifth)
    {
        double slow = 0.92 + 0.08 * Math.Sin(Tau * 0.13 * t);
        return slow * (0.48 * Math.Sin(Tau * root * t) + 0.31 * Math.Sin(Tau * third * t + 0.2) + 0.22 * Math.Sin(Tau * fifth * t + 0.5));
    }

    private static void WriteEffect(string path, string kind, double duration)
    {
        int length = (int)(duration * SampleRate);
        double[] mono = new double[length];
        for (int i = 0; i < length; i++)
        {
            double t = i / (double)SampleRate;
            double u = t / duration;
            double n = Noise(i);
            double value = 0.0;
            if (kind == "jump")
            {
                value = 0.34 * Math.Sin(Tau * (260.0 + 470.0 * u) * t) * Math.Pow(1.0 - u, 1.3) + 0.06 * n * (1.0 - u);
            }
            else if (kind == "dash")
            {
                double env = Math.Pow(Math.Sin(Math.PI * u), 1.15);
                value = env * (0.34 * Math.Sin(Tau * (1050.0 - 760.0 * u) * t) + 0.16 * n);
            }
            else if (kind == "slash")
            {
                double env = Math.Pow(Math.Sin(Math.PI * u), 1.4);
                value = env * (0.24 * Math.Sin(Tau * (1750.0 - 1280.0 * u) * t) + 0.19 * n);
            }
            else if (kind == "spin")
            {
                double sweep = 0.0;
                for (int p = 0; p < 3; p++)
                {
                    double q = (u - (0.06 + p * 0.30)) / 0.29;
                    if (q >= 0.0 && q <= 1.0)
                        sweep += Math.Sin(Math.PI * q) * Math.Sin(Tau * (1500.0 - 950.0 * q) * t);
                }
                value = 0.24 * sweep + 0.08 * n * Math.Sin(Math.PI * u);
            }
            else if (kind == "thrust")
            {
                double env = Math.Min(1.0, t / 0.025) * Math.Exp(-u * 5.5);
                value = env * (0.42 * Math.Sin(Tau * (460.0 + 280.0 * u) * t) + 0.18 * n);
            }
            else if (kind == "hit")
            {
                double env = Math.Exp(-u * 10.0);
                value = env * (0.52 * Math.Sin(Tau * (118.0 - 45.0 * u) * t) + 0.25 * n);
            }
            else if (kind == "blood")
            {
                double[] notes = { 523.25, 659.25, 783.99, 1046.50 };
                for (int j = 0; j < notes.Length; j++)
                {
                    double age = t - j * 0.13;
                    if (age >= 0.0)
                        value += 0.19 * Math.Sin(Tau * notes[j] * age) * Math.Exp(-age * 4.0);
                }
                value += 0.07 * n * Math.Exp(-u * 4.0);
            }
            else if (kind == "execution")
            {
                double low = Math.Sin(Tau * (82.0 - 25.0 * u) * t) * Math.Exp(-u * 6.0);
                double age = Math.Max(0.0, t - 0.16);
                double bell = age > 0.0 ? Math.Sin(Tau * 392.0 * age) * Math.Exp(-age * 3.8) : 0.0;
                value = 0.42 * low + 0.21 * bell + 0.13 * n * Math.Exp(-u * 8.0);
            }
            else if (kind == "wolf")
            {
                double howlEnv = Math.Pow(Math.Sin(Math.PI * u), 0.8);
                double pitch = 210.0 - 110.0 * u + 12.0 * Math.Sin(Tau * 3.0 * u);
                value = howlEnv * (0.34 * Math.Sin(Tau * pitch * t) + 0.13 * Math.Sin(Tau * pitch * 1.51 * t) + 0.07 * n);
            }
            double fadeIn = Math.Min(1.0, t / 0.008);
            double fadeOut = Math.Min(1.0, Math.Max(0.0, (duration - t) / 0.018));
            mono[i] = Clamp(value * fadeIn * fadeOut, -0.85, 0.85);
        }
        WriteWav(path, mono, null, SampleRate);
    }

    private static double Noise(int index)
    {
        uint x = (uint)index * 747796405u + 2891336453u;
        x = ((x >> (int)(x >> 28) + 4) ^ x) * 277803737u;
        x = (x >> 22) ^ x;
        return (x & 0x00ffffffu) / 8388608.0 - 1.0;
    }

    private static double Clamp(double value, double min, double max)
    {
        return Math.Max(min, Math.Min(max, value));
    }

    private static void WriteWav(string path, double[] left, double[] right, int sampleRate)
    {
        int channels = right == null ? 1 : 2;
        int dataSize = left.Length * channels * 2;
        using (BinaryWriter writer = new BinaryWriter(File.Create(path)))
        {
            writer.Write(System.Text.Encoding.ASCII.GetBytes("RIFF"));
            writer.Write(36 + dataSize);
            writer.Write(System.Text.Encoding.ASCII.GetBytes("WAVE"));
            writer.Write(System.Text.Encoding.ASCII.GetBytes("fmt "));
            writer.Write(16);
            writer.Write((short)1);
            writer.Write((short)channels);
            writer.Write(sampleRate);
            writer.Write(sampleRate * channels * 2);
            writer.Write((short)(channels * 2));
            writer.Write((short)16);
            writer.Write(System.Text.Encoding.ASCII.GetBytes("data"));
            writer.Write(dataSize);
            for (int i = 0; i < left.Length; i++)
            {
                writer.Write((short)(Clamp(left[i], -1.0, 1.0) * 32767.0));
                if (right != null)
                    writer.Write((short)(Clamp(right[i], -1.0, 1.0) * 32767.0));
            }
        }
    }
}
