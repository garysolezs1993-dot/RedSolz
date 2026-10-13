using System;
using System.IO;
using System.Numerics;

// Processes a supplied recording; does not replace any gameplay sound automatically.
public static class DarkWolfHowl
{
    private const double Tau = Math.PI * 2;

    public static string Render(string source, string destination)
    {
        int rate, channels;
        double[][] input = Read(source, out rate, out channels);
        int sourceLength = input[0].Length;
        double[] mono = new double[sourceLength];
        for (int i = 0; i < sourceLength; i++)
            mono[i] = (input[0][i] + input[Math.Min(1, channels - 1)][i]) * .5;

        double[] body = Pitch(mono, Math.Pow(2, -5.0 / 12));
        double[] undertone = Pitch(mono, .5);
        body = Filter(Filter(body, rate, 65, true), rate, 3200, false);
        undertone = Filter(Filter(undertone, rate, 45, true), rate, 1050, false);
        int length = sourceLength + (int)(rate * 1.1);
        double[] left = new double[length], right = new double[length];
        double[] dryL = Filter(Filter(input[0], rate, 45, true), rate, 6500, false);
        double[] dryR = Filter(Filter(input[Math.Min(1, channels - 1)], rate, 45, true), rate, 6500, false);
        int bodyDelay = (int)(rate * .025), lowDelay = (int)(rate * .055);
        for (int i = 0; i < sourceLength; i++)
        {
            double edge = Math.Min(1, i / (rate * .015));
            edge *= Math.Min(1, (sourceLength - i) / (rate * .035));
            left[i] += dryL[i] * .84 * edge;
            right[i] += dryR[i] * .84 * edge;
            // Small offsets and opposite stereo weighting prevent exact doubling.
            left[i + bodyDelay] += body[i] * .30 * edge;
            right[i + bodyDelay + (int)(rate * .008)] += body[i] * .24 * edge;
            left[i + lowDelay] += undertone[i] * .105 * edge;
            right[i + lowDelay] += undertone[i] * .135 * edge;
        }

        double[] send = new double[length];
        for (int i = 0; i < length; i++)
            send[i] = (left[i] + right[i]) * .5;
        double[] wetL = Reverb(send, rate, false), wetR = Reverb(send, rate, true);
        double peak = 0, sum = 0;
        for (int i = 0; i < length; i++)
        {
            left[i] = Math.Tanh((left[i] + wetL[i] * .17) * 1.12) / 1.12;
            right[i] = Math.Tanh((right[i] + wetR[i] * .17) * 1.12) / 1.12;
            double tail = Math.Min(1, (length - i) / (rate * .22));
            left[i] *= tail;
            right[i] *= tail;
            peak = Math.Max(peak, Math.Max(Math.Abs(left[i]), Math.Abs(right[i])));
        }
        double gain = Math.Pow(10, -1.5 / 20) / Math.Max(peak, .000001);
        for (int i = 0; i < length; i++)
        {
            left[i] *= gain;
            right[i] *= gain;
            sum += left[i] * left[i] + right[i] * right[i];
        }
        Write(destination, left, right, rate);
        return String.Format("Source: {0:F3}s; Output: {1:F3}s; {2}Hz stereo PCM16; peak -1.5dBFS; RMS {3:F1}dBFS; pitch layers -5 / -12 semitones",
            sourceLength / (double)rate, length / (double)rate, rate, 20 * Math.Log10(Math.Sqrt(sum / (length * 2))));
    }

    private static double[][] Read(string path, out int rate, out int channels)
    {
        byte[] bytes = File.ReadAllBytes(path);
        if (System.Text.Encoding.ASCII.GetString(bytes, 0, 4) != "RIFF" ||
            System.Text.Encoding.ASCII.GetString(bytes, 8, 4) != "WAVE")
            throw new InvalidDataException("Expected a RIFF WAVE file");
        rate = 0; channels = 0;
        int format = 0, bits = 0, start = -1, size = 0;
        for (int p = 12; p + 8 <= bytes.Length;)
        {
            string id = System.Text.Encoding.ASCII.GetString(bytes, p, 4);
            int n = BitConverter.ToInt32(bytes, p + 4);
            if (id == "fmt ")
            {
                format = BitConverter.ToUInt16(bytes, p + 8);
                channels = BitConverter.ToUInt16(bytes, p + 10);
                rate = BitConverter.ToInt32(bytes, p + 12);
                bits = BitConverter.ToUInt16(bytes, p + 22);
            }
            if (id == "data") { start = p + 8; size = n; }
            p += 8 + n + (n & 1);
        }
        if (format != 1 || bits != 16 || channels < 1 || channels > 2 || start < 0 || rate < 1)
            throw new InvalidDataException("Expected mono/stereo 16-bit PCM WAV");
        int frames = size / (channels * 2);
        double[][] result = new double[channels][];
        for (int c = 0; c < channels; c++)
        {
            result[c] = new double[frames];
            for (int i = 0; i < frames; i++)
                result[c][i] = BitConverter.ToInt16(bytes, start + (i * channels + c) * 2) / 32768.0;
        }
        return result;
    }

    public static string FitAttack(string sourcePath, string destination, double duration, double releaseTime)
    {
        int rate, channels;
        double[][] source = Read(sourcePath, out rate, out channels);
        int block = (int)(rate * .15), peakAt = 0;
        double greatest = 0;
        for (int start = 0; start + block < source[0].Length; start += block / 2)
        {
            double energy = 0;
            for (int i = start; i < start + block; i++)
                energy += source[0][i] * source[0][i] + source[Math.Min(1, channels - 1)][i] * source[Math.Min(1, channels - 1)][i];
            if (energy > greatest) { greatest = energy; peakAt = start + block / 2; }
        }
        // Keep a coherent two-second phrase instead of crushing the whole long howl.
        int phraseLength = Math.Min((int)(rate * 2.0), source[0].Length);
        int phraseStart = Math.Max(0, Math.Min(source[0].Length - phraseLength, peakAt - phraseLength / 2));
        int target = (int)Math.Round(rate * duration);
        double[][] fitted = new double[2][];
        double peak = 0;
        for (int c = 0; c < 2; c++)
        {
            double[] phrase = new double[phraseLength];
            Array.Copy(source[Math.Min(c, channels - 1)], phraseStart, phrase, 0, phraseLength);
            fitted[c] = Stretch(phrase, target);
            for (int i = 0; i < target; i++)
            {
                double t = i / (double)rate;
                double swell = t <= releaseTime ? Math.Sin(Math.PI * .5 * t / releaseTime)
                    : Math.Cos(Math.PI * .5 * (t - releaseTime) / (duration - releaseTime));
                double edge = Math.Min(1, i / (rate * .018)) * Math.Min(1, (target - 1 - i) / (rate * .09));
                fitted[c][i] *= (.12 + .88 * Math.Pow(Math.Max(0, swell), 1.2)) * edge;
                peak = Math.Max(peak, Math.Abs(fitted[c][i]));
            }
        }
        double gain = Math.Pow(10, -3.0 / 20) / Math.Max(peak, .000001);
        for (int c = 0; c < 2; c++) for (int i = 0; i < target; i++) fitted[c][i] *= gain;
        Write(destination, fitted[0], fitted[1], rate);
        return String.Format("Boss attack howl: {0:F6}s; burst at {1:F6}s; pitch preserved; stereo {2}Hz PCM16; peak -3dBFS", target / (double)rate, releaseTime, rate);
    }

    private static double[] Pitch(double[] source, double ratio)
    {
        double[] compressed = Stretch(source, (int)Math.Round(source.Length * ratio));
        double[] result = new double[source.Length];
        for (int i = 0; i < result.Length; i++)
        {
            double position = i * ratio;
            int at = (int)position;
            if (at + 1 < compressed.Length)
                result[i] = compressed[at] * (1 - (position - at)) + compressed[at + 1] * (position - at);
        }
        return result;
    }

    private static double[] Stretch(double[] source, int target)
    {
        // Duration fitting preserves pitch, including the already-layered dark timbre.
        const int n = 4096, hop = 512;
        double speed = source.Length / (double)target;
        int frames = (int)Math.Ceiling(source.Length / (hop * speed));
        double[] window = new double[n], output = new double[frames * hop + n];
        double[] weight = new double[output.Length], previous = new double[n / 2 + 1];
        double[] phaseSum = new double[previous.Length];
        Complex[] spectrum = new Complex[n];
        for (int j = 0; j < n; j++) window[j] = .5 - .5 * Math.Cos(Tau * j / (n - 1));
        int previousStart = 0;
        for (int f = 0; f < frames; f++)
        {
            int start = (int)Math.Round(f * hop * speed) - n / 2;
            for (int j = 0; j < n; j++)
            {
                int index = start + j;
                spectrum[j] = new Complex(index >= 0 && index < source.Length ? source[index] * window[j] : 0, 0);
            }
            FFT(spectrum, false);
            int actualHop = start - previousStart;
            for (int k = 0; k <= n / 2; k++)
            {
                double phase = Math.Atan2(spectrum[k].Imaginary, spectrum[k].Real);
                double frequency = Tau * k / n;
                if (f == 0) phaseSum[k] = phase;
                else
                {
                    double deviation = phase - previous[k] - frequency * actualHop;
                    deviation -= Tau * Math.Round(deviation / Tau);
                    phaseSum[k] += frequency * hop + deviation * hop / actualHop;
                }
                previous[k] = phase;
                spectrum[k] = Complex.FromPolarCoordinates(spectrum[k].Magnitude, phaseSum[k]);
                if (k > 0 && k < n / 2) spectrum[n - k] = Complex.Conjugate(spectrum[k]);
            }
            previousStart = start;
            FFT(spectrum, true);
            for (int j = 0; j < n; j++)
            {
                int at = f * hop + j;
                output[at] += spectrum[j].Real * window[j];
                weight[at] += window[j] * window[j];
            }
        }
        for (int i = 0; i < output.Length; i++) output[i] /= Math.Max(weight[i], .00001);
        double[] result = new double[target];
        // The centered analysis frame puts the signal origin at half an FFT window.
        for (int i = 0; i < result.Length; i++)
        {
            double position = n / 2 + i;
            int at = (int)position;
            if (at + 1 < output.Length)
                result[i] = output[at] * (1 - (position - at)) + output[at + 1] * (position - at);
        }
        return result;
    }

    private static void FFT(Complex[] a, bool inverse)
    {
        int n = a.Length;
        for (int i = 1, j = 0; i < n; i++)
        {
            int bit = n >> 1;
            for (; (j & bit) != 0; bit >>= 1) j ^= bit;
            j ^= bit;
            if (i < j) { Complex swap = a[i]; a[i] = a[j]; a[j] = swap; }
        }
        for (int len = 2; len <= n; len <<= 1)
        {
            Complex step = Complex.FromPolarCoordinates(1, (inverse ? 1 : -1) * Tau / len);
            for (int i = 0; i < n; i += len)
            {
                Complex w = Complex.One;
                for (int j = 0; j < len / 2; j++)
                {
                    Complex u = a[i + j], v = a[i + j + len / 2] * w;
                    a[i + j] = u + v; a[i + j + len / 2] = u - v; w *= step;
                }
            }
        }
        if (inverse) for (int i = 0; i < n; i++) a[i] /= n;
    }

    private static double[] Filter(double[] x, int rate, double cutoff, bool highpass)
    {
        double omega = Tau * cutoff / rate, cs = Math.Cos(omega), sn = Math.Sin(omega);
        double alpha = sn / (2 * .7071067811865476), a0 = 1 + alpha;
        double b0 = (1 + (highpass ? cs : -cs)) / (2 * a0);
        double b1 = (highpass ? -(1 + cs) : 1 - cs) / a0, b2 = b0;
        double a1 = -2 * cs / a0, a2 = (1 - alpha) / a0;
        double z1 = 0, z2 = 0;
        double[] y = new double[x.Length];
        for (int i = 0; i < x.Length; i++)
        {
            y[i] = b0 * x[i] + z1;
            z1 = b1 * x[i] - a1 * y[i] + z2;
            z2 = b2 * x[i] - a2 * y[i];
        }
        return y;
    }

    private static double[] Reverb(double[] x, int rate, bool right)
    {
        double[] result = new double[x.Length];
        double[] times = { .047, .059, .071, .083 };
        for (int c = 0; c < times.Length; c++)
        {
            int delay = (int)(rate * (times[c] + (right ? .0023 : 0)));
            double feedback = Math.Pow(10, -3 * delay / (rate * .85));
            double damping = 1 - Math.Exp(-Tau * 2200 / rate), filtered = 0;
            double[] buffer = new double[delay];
            for (int i = 0; i < x.Length; i++)
            {
                int at = i % delay;
                double delayed = buffer[at];
                filtered += damping * (delayed - filtered);
                buffer[at] = x[i] + filtered * feedback;
                result[i] += delayed * .25;
            }
        }
        foreach (double time in new double[] { .0072, .0031 })
        {
            int delay = (int)(rate * (time + (right ? .0004 : 0)));
            double[] buffer = new double[delay];
            for (int i = 0; i < result.Length; i++)
            {
                int at = i % delay;
                double delayed = buffer[at], original = result[i];
                result[i] = delayed - original * .5;
                buffer[at] = original + delayed * .5;
            }
        }
        return result;
    }

    private static void Write(string path, double[] left, double[] right, int rate)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        using (BinaryWriter b = new BinaryWriter(File.Create(path)))
        {
            int bytes = left.Length * 4;
            b.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); b.Write(bytes + 36);
            b.Write(System.Text.Encoding.ASCII.GetBytes("WAVEfmt ")); b.Write(16);
            b.Write((short)1); b.Write((short)2); b.Write(rate); b.Write(rate * 4);
            b.Write((short)4); b.Write((short)16);
            b.Write(System.Text.Encoding.ASCII.GetBytes("data")); b.Write(bytes);
            for (int i = 0; i < left.Length; i++)
            {
                b.Write((short)Math.Round(Math.Max(-1, Math.Min(1, left[i])) * 32767));
                b.Write((short)Math.Round(Math.Max(-1, Math.Min(1, right[i])) * 32767));
            }
        }
    }
}
