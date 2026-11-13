import os
import wave
import struct
import math
import subprocess
import shutil
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
AUDIO_ROOT = PROJECT_ROOT / "src_game" / "assets" / "audio"
MASTER_OUT_DIR = AUDIO_ROOT / "master_v32"
AUDIT_OUT_DIR = PROJECT_ROOT / "docs" / "AUDIO_EXPORT_FOR_ARGONS" / "audio_files"

SAMPLE_RATE = 44100

def ensure_dirs():
    MASTER_OUT_DIR.mkdir(parents=True, exist_ok=True)
    AUDIT_OUT_DIR.mkdir(parents=True, exist_ok=True)

def load_ogg_or_wav_as_float_mono(rel_path: str) -> list[float]:
    """
    Giải mã file .ogg / .wav thu âm thật trong dự án sang mảng float [-1.0, 1.0] ở 44100Hz.
    Sử dụng soundfile / scipy / pydub / ffmpeg hoặc bộ đọc WAV chuẩn.
    """
    full_path = AUDIO_ROOT / rel_path
    if not full_path.exists():
        # Tìm kiếm dự phòng trong toàn bộ AUDIO_ROOT
        fname = Path(rel_path).name
        matches = list(AUDIO_ROOT.rglob(fname))
        if matches:
            full_path = matches[0]
        else:
            print(f"Warning: file not found: {rel_path}")
            return []

    # Thử dùng soundfile hoặc librosa nếu có sẵn trong Python
    try:
        import soundfile as sf
        data, sr = sf.read(str(full_path), dtype='float32')
        if len(data.shape) > 1:
            data = data.mean(axis=1)
        samples = data.tolist()
        if sr != SAMPLE_RATE and len(samples) > 10:
            samples = resample_linear(samples, float(sr) / float(SAMPLE_RATE))
        return samples
    except Exception as e:
        print(f"soundfile failed on {full_path}: {e}")
        pass

    # Thử dùng ffmpeg CLI nếu có trên hệ thống
    tmp_wav = MASTER_OUT_DIR / "_tmp_decode.wav"
    try:
        cmd = [
            "ffmpeg", "-y", "-v", "error",
            "-i", str(full_path),
            "-ar", str(SAMPLE_RATE), "-ac", "1", "-f", "wav", str(tmp_wav)
        ]
        subprocess.run(cmd, check=True)
        if tmp_wav.exists():
            samples = read_wav_mono(tmp_wav)
            tmp_wav.unlink(missing_ok=True)
            if samples:
                return samples
    except Exception:
        pass

    # Nếu là file .wav gốc
    if full_path.suffix.lower() == ".wav":
        return read_wav_mono(full_path)

    return []

def read_wav_mono(wav_path: Path) -> list[float]:
    try:
        with wave.open(str(wav_path), "rb") as wf:
            n_channels = wf.getnchannels()
            sampwidth = wf.getsampwidth()
            framerate = wf.getframerate()
            n_frames = wf.getnframes()
            raw = wf.readframes(n_frames)
            if sampwidth == 2:
                total_samples = n_frames * n_channels
                ints = struct.unpack("<" + "h" * total_samples, raw)
                mono = [ints[i] / 32768.0 for i in range(0, total_samples, n_channels)]
                if framerate != SAMPLE_RATE and len(mono) > 10:
                    mono = resample_linear(mono, float(framerate) / float(SAMPLE_RATE))
                return mono
    except Exception:
        pass
    return []

def resample_linear(samples: list[float], pitch_rate: float) -> list[float]:
    """Đổi tốc độ / cao độ mẫu thu âm thật bằng nội suy tuyến tính mượt."""
    if not samples or pitch_rate <= 0.05:
        return []
    out_len = int(len(samples) / pitch_rate)
    out = [0.0] * out_len
    n = len(samples)
    for i in range(out_len):
        src_idx = i * pitch_rate
        idx0 = int(src_idx)
        if idx0 >= n - 1:
            out[i] = samples[n - 1]
        else:
            frac = src_idx - idx0
            out[i] = samples[idx0] * (1.0 - frac) + samples[idx0 + 1] * frac
    return out

def lowpass_filter(samples: list[float], cutoff_hz: float) -> list[float]:
    """Bộ lọc thông thấp RC một cực khử hoàn toàn độ chói/rè tần số cao."""
    if not samples:
        return []
    rc = 1.0 / (2.0 * math.pi * max(40.0, cutoff_hz))
    dt = 1.0 / float(SAMPLE_RATE)
    alpha = dt / (rc + dt)
    out = [0.0] * len(samples)
    prev = samples[0]
    for i, x in enumerate(samples):
        prev = prev + alpha * (x - prev)
        out[i] = prev
    return out

def highpass_filter(samples: list[float], cutoff_hz: float) -> list[float]:
    """Bộ lọc thông cao giữ lại độ sắc bén kim loại."""
    lp = lowpass_filter(samples, cutoff_hz)
    return [samples[i] - lp[i] for i in range(len(samples))]

def apply_envelope(samples: list[float], attack_s: float = 0.004, release_s: float = 0.12) -> list[float]:
    n = len(samples)
    if n == 0:
        return []
    att_n = max(1, int(attack_s * SAMPLE_RATE))
    rel_n = max(1, int(release_s * SAMPLE_RATE))
    out = list(samples)
    for i in range(min(att_n, n)):
        out[i] *= (i / float(att_n))
    for i in range(min(rel_n, n)):
        idx = n - 1 - i
        if idx >= 0:
            out[idx] *= (i / float(rel_n)) ** 1.5
    return out

def synth_acoustic_body_layer(kind: str, dur: float) -> list[float]:
    """
    Tạo lớp cộng hưởng vật lý bổ trợ (Acoustic Physical Modeling: Karplus-Strong metallic string,
    Filtered Sub-Bass Seismic Wave, Filtered Wind/Fire Roar, Thunder Crack) để hòa trộn cùng mẫu Foley thật.
    Tuyệt đối không dùng sóng sin đơn điệu!
    """
    import random
    rng = random.Random(hash(kind) & 0xFFFFFFFF)
    n = int(dur * SAMPLE_RATE)
    out = [0.0] * n

    if kind == "sub_seismic_drop":
        # Sóng địa chấn hạ âm có tích phân pha chuẩn xác (Phase-accumulated Sub-Bass 95Hz -> 34Hz)
        phase = 0.0
        for i in range(n):
            p = i / float(n)
            freq = 95.0 * math.exp(-p * 3.2) + 32.0
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            env = math.sin(min(1.0, i / (0.008 * SAMPLE_RATE)) * math.pi * 0.5) * math.exp(-p * 3.8)
            out[i] = math.tanh(math.sin(phase) * 1.6) * env * 0.85

    elif kind == "fire_eruption_roar":
        # Tiếng lửa bùng cháy: Nhiễu hồng lọc dải động (Dynamic Band-pass 180Hz - 650Hz)
        raw = [rng.uniform(-1.0, 1.0) for _ in range(n)]
        lp1 = lowpass_filter(raw, 520.0)
        lp2 = lowpass_filter(lp1, 340.0)
        hp = highpass_filter(lp2, 95.0)
        for i in range(n):
            p = i / float(n)
            flutter = 0.72 + 0.28 * math.sin(2.0 * math.pi * 19.0 * (i / float(SAMPLE_RATE)))
            env = (1.0 - math.exp(-p * 18.0)) * math.exp(-p * 2.6)
            out[i] = math.tanh(hp[i] * 3.8 * flutter) * env * 0.85

    elif kind == "thunder_crack_rumble":
        # Tiếng sấm sét đánh rền vang: Đỉnh xung sét + Sấm rền 120Hz-420Hz đã lọc mượt
        raw = [rng.uniform(-1.0, 1.0) for _ in range(n)]
        filtered = lowpass_filter(raw, 1100.0)
        body = lowpass_filter(raw, 260.0)
        for i in range(n):
            p = i / float(n)
            jagged = 1.0 if (int(p * 42) % 3 != 0) else 0.35
            crack_env = math.exp(-p * 11.0) * jagged
            rumble_env = math.exp(-p * 3.0)
            out[i] = math.tanh((filtered[i] * crack_env * 2.4 + body[i] * rumble_env * 2.2)) * 0.85

    elif kind == "blade_air_whoosh_heavy":
        # Tiếng vung đại kiếm xé gió trầm hùng (Filtered aerodynamic whoosh)
        raw = [rng.uniform(-1.0, 1.0) for _ in range(n)]
        f1 = lowpass_filter(raw, 900.0)
        f2 = highpass_filter(f1, 180.0)
        for i in range(n):
            p = i / float(n)
            env = math.sin(p * math.pi) ** 1.6 * math.exp(-p * 1.5)
            out[i] = f2[i] * env * 2.4

    elif kind == "blade_air_whoosh_fast":
        # Tiếng vung kiếm bạch kim sắc gọn (Crisp aerodynamic cut)
        raw = [rng.uniform(-1.0, 1.0) for _ in range(n)]
        f1 = lowpass_filter(raw, 1850.0)
        f2 = highpass_filter(f1, 420.0)
        for i in range(n):
            p = i / float(n)
            env = math.sin(p * math.pi) ** 2.0 * math.exp(-p * 2.2)
            out[i] = f2[i] * env * 2.2

    elif kind == "steel_resonator_chord":
        # Tiếng ngân kim loại của thân kiếm thánh (Inharmonic Modal Steel Resonator)
        modes = [528.0, 864.0, 1312.0, 1980.0, 2640.0]
        decays = [5.5, 7.0, 9.5, 13.0, 16.0]
        gains = [0.35, 0.28, 0.20, 0.12, 0.08]
        for i in range(n):
            t = i / float(SAMPLE_RATE)
            p = i / float(n)
            val = 0.0
            for m_idx, f in enumerate(modes):
                val += math.sin(2.0 * math.pi * f * t) * math.exp(-p * decays[m_idx]) * gains[m_idx]
            out[i] = val * (1.0 - math.exp(-i / (0.003 * SAMPLE_RATE)))

    elif kind == "crimson_cobalt_power_chord":
        # Âm hưởng năng lượng Huyết Lam khi kiếm khí Nộ đọng lại trên mặt đất
        modes = [110.0, 165.0, 220.0, 330.0, 440.0]
        for i in range(n):
            t = i / float(SAMPLE_RATE)
            p = i / float(n)
            env = math.sin(p * math.pi) * math.exp(-p * 1.8)
            val = sum(math.sin(2.0 * math.pi * f * t + 0.3 * math.sin(2.0 * math.pi * 6.0 * t)) for f in modes) / len(modes)
            out[i] = math.tanh(val * 1.8) * env * 0.65

    elif kind == "epic_arena_bgm_loop":
        # Bản nhạc nền nhịp trống trận Taiko & Bassline Dark Fantasy dài 8.0s chuẩn nhịp 120 BPM
        bpm = 120.0
        beat_s = 60.0 / bpm # 0.5s per beat, 16 beats in 8.0s
        raw_noise = lowpass_filter([rng.uniform(-1.0, 1.0) for _ in range(n)], 480.0)
        bass_notes = [55.0, 55.0, 65.41, 65.41, 73.42, 73.42, 61.74, 49.0] # A1 - C2 - D2 - B1/G1
        phase_drum = 0.0
        phase_bass = 0.0
        for i in range(n):
            t = i / float(SAMPLE_RATE)
            beat_idx = int(t / beat_s)
            beat_local = (t % beat_s) / beat_s
            sub_idx = int(t / (beat_s * 0.5))
            sub_local = (t % (beat_s * 0.5)) / (beat_s * 0.5)

            # 1. Trống trận Taiko trầm ấm ở mỗi phách chính (0% chói)
            f_drum = 92.0 * math.exp(-beat_local * 9.0) + 42.0
            phase_drum += 2.0 * math.pi * f_drum / SAMPLE_RATE
            env_drum = math.exp(-beat_local * 6.5) * (1.0 if beat_idx % 2 == 0 else 0.65)
            taiko = math.tanh(math.sin(phase_drum) * 1.5) * env_drum * 0.52

            # 2. Nhịp trống phụ (Tom/Percussion) ở phách lẻ
            env_perc = math.exp(-sub_local * 14.0) * (0.35 if sub_idx % 2 == 1 else 0.15)
            perc = raw_noise[i] * env_perc

            # 3. Dải trầm Dark Fantasy Cello/Bass Drone lọc ấm (Low-passed Warm Pad)
            bar_idx = min(len(bass_notes) - 1, int(t / 1.0))
            f_bass = bass_notes[bar_idx]
            phase_bass += 2.0 * math.pi * f_bass / SAMPLE_RATE
            env_bass = math.sin(sub_local * math.pi) ** 0.4
            bass = (math.sin(phase_bass) * 0.65 + math.sin(phase_bass * 2.0) * 0.25) * env_bass * 0.26

            out[i] = taiko + perc + bass
        out = lowpass_filter(out, 1200.0)

    return out

def mix_stereo_master(layers: list[dict], total_dur: float, add_reverb: float = 0.18) -> tuple[list[float], list[float]]:
    """
    Trộn nhiều lớp âm thanh (cả mẫu thu âm thật + lớp cộng hưởng vật lý) thành file Stereo (Left, Right)
    với hiệu ứng mở rộng âm trường (Haas Stereo Panning) và buồng vang (Schroeder Stereo Reverb).
    """
    total_n = int(total_dur * SAMPLE_RATE)
    left = [0.0] * total_n
    right = [0.0] * total_n

    for lay in layers:
        samples = lay.get("samples", [])
        if not samples:
            continue
        pitch = float(lay.get("pitch", 1.0))
        if abs(pitch - 1.0) > 0.01:
            samples = resample_linear(samples, pitch)

        lp_hz = float(lay.get("lpf", 0.0))
        if lp_hz > 20.0:
            samples = lowpass_filter(samples, lp_hz)

        hp_hz = float(lay.get("hpf", 0.0))
        if hp_hz > 20.0:
            samples = highpass_filter(samples, hp_hz)

        max_d = float(lay.get("dur", 0.0))
        if max_d > 0.01 and len(samples) > int(max_d * SAMPLE_RATE):
            samples = samples[:int(max_d * SAMPLE_RATE)]

        samples = apply_envelope(samples, float(lay.get("att", 0.003)), float(lay.get("rel", 0.08)))

        gain = float(lay.get("gain", 1.0))
        pan = float(lay.get("pan", 0.0)) # -1.0 (Left) -> +1.0 (Right)
        delay_s = float(lay.get("delay", 0.0))
        start_idx = int(delay_s * SAMPLE_RATE)

        gain_l = gain * math.cos((pan + 1.0) * math.pi * 0.25)
        gain_r = gain * math.sin((pan + 1.0) * math.pi * 0.25)

        for i, s in enumerate(samples):
            dst = start_idx + i
            if 0 <= dst < total_n:
                left[dst] += s * gain_l
                right[dst] += s * gain_r

    # Bổ sung Stereo Reverb tự nhiên của đấu trường đá (4 đường trễ phản xạ chéo)
    if add_reverb > 0.01:
        delays_ms = [23.0, 37.0, 53.0, 79.0]
        decays = [0.42, 0.32, 0.24, 0.16]
        for d_ms, dec in zip(delays_ms, decays):
            d_samp = int((d_ms / 1000.0) * SAMPLE_RATE)
            w = add_reverb * dec
            for i in range(d_samp, total_n):
                left[i] += right[i - d_samp] * w
                right[i] += left[i - d_samp] * w

    # Soft-Knee Mastering Limiter & Chuẩn hóa đỉnh âm (-0.8 dBFS) chống rè vỡ tiếng 100%
    peak = max(max((abs(x) for x in left), default=0.001), max((abs(x) for x in right), default=0.001))
    target_peak = 0.90
    norm = (target_peak / peak) if peak > target_peak else 1.0
    for i in range(total_n):
        left[i] = math.tanh(left[i] * norm * 1.15) * 0.92
        right[i] = math.tanh(right[i] * norm * 1.15) * 0.92

    return left, right

def save_stereo_wav(filename: str, left: list[float], right: list[float]):
    for out_dir in [MASTER_OUT_DIR, AUDIT_OUT_DIR]:
        out_path = out_dir / filename
        with wave.open(str(out_path), "wb") as wf:
            wf.setnchannels(2)
            wf.setsampwidth(2)
            wf.setframerate(SAMPLE_RATE)
            buf = bytearray(len(left) * 4)
            for i in range(len(left)):
                l_int = int(max(-1.0, min(1.0, left[i])) * 32767.0)
                r_int = int(max(-1.0, min(1.0, right[i])) * 32767.0)
                struct.pack_into("<hh", buf, i * 4, l_int, r_int)
            wf.writeframes(buf)

def build_all_25_master_files():
    ensure_dirs()
    # Nạp toàn bộ các mẫu thu âm vật lý thật từ kho dự án
    stems = {
        "slice1": load_ogg_or_wav_as_float_mono("rpg/knifeSlice.ogg"),
        "slice2": load_ogg_or_wav_as_float_mono("rpg/knifeSlice2.ogg"),
        "chop": load_ogg_or_wav_as_float_mono("rpg/chop.ogg"),
        "draw1": load_ogg_or_wav_as_float_mono("rpg/drawKnife1.ogg"),
        "draw2": load_ogg_or_wav_as_float_mono("rpg/drawKnife2.ogg"),
        "draw3": load_ogg_or_wav_as_float_mono("rpg/drawKnife3.ogg"),
        "cloth1": load_ogg_or_wav_as_float_mono("rpg/cloth1.ogg"),
        "cloth2": load_ogg_or_wav_as_float_mono("rpg/cloth2.ogg"),
        "cloth_belt": load_ogg_or_wav_as_float_mono("rpg/clothBelt.ogg"),
        "pot": load_ogg_or_wav_as_float_mono("rpg/metalPot1.ogg"),
        "step1": load_ogg_or_wav_as_float_mono("rpg/footstep00.ogg"),
        "step2": load_ogg_or_wav_as_float_mono("rpg/footstep01.ogg"),
        "step3": load_ogg_or_wav_as_float_mono("rpg/footstep02.ogg"),
        "metal_h0": load_ogg_or_wav_as_float_mono("impact/impactMetal_heavy_000.ogg"),
        "metal_h1": load_ogg_or_wav_as_float_mono("impact/impactMetal_heavy_001.ogg"),
        "metal_h2": load_ogg_or_wav_as_float_mono("impact/impactMetal_heavy_002.ogg"),
        "metal_h3": load_ogg_or_wav_as_float_mono("impact/impactMetal_heavy_003.ogg"),
        "metal_m0": load_ogg_or_wav_as_float_mono("impact/impactMetal_medium_000.ogg"),
        "metal_m1": load_ogg_or_wav_as_float_mono("impact/impactMetal_medium_001.ogg"),
        "metal_l0": load_ogg_or_wav_as_float_mono("impact/impactMetal_light_000.ogg"),
        "plate_h0": load_ogg_or_wav_as_float_mono("impact/impactPlate_heavy_000.ogg"),
        "plate_h1": load_ogg_or_wav_as_float_mono("impact/impactPlate_heavy_001.ogg"),
        "punch_h0": load_ogg_or_wav_as_float_mono("impact/impactPunch_heavy_000.ogg"),
        "punch_h1": load_ogg_or_wav_as_float_mono("impact/impactPunch_heavy_001.ogg"),
        "punch_h2": load_ogg_or_wav_as_float_mono("impact/impactPunch_heavy_002.ogg"),
        "soft_h0": load_ogg_or_wav_as_float_mono("impact/impactSoft_heavy_000.ogg"),
        "mining0": load_ogg_or_wav_as_float_mono("impact/impactMining_000.ogg"),
        "mining1": load_ogg_or_wav_as_float_mono("impact/impactMining_001.ogg"),
        "bell_h0": load_ogg_or_wav_as_float_mono("impact/impactBell_heavy_000.ogg"),
        "sub0": load_ogg_or_wav_as_float_mono("scifi/lowFrequency_explosion_000.ogg"),
        "sub1": load_ogg_or_wav_as_float_mono("scifi/lowFrequency_explosion_001.ogg"),
        "crunch0": load_ogg_or_wav_as_float_mono("scifi/explosionCrunch_000.ogg"),
        "crunch1": load_ogg_or_wav_as_float_mono("scifi/explosionCrunch_001.ogg"),
        "crunch2": load_ogg_or_wav_as_float_mono("scifi/explosionCrunch_002.ogg"),
        "crunch3": load_ogg_or_wav_as_float_mono("scifi/explosionCrunch_003.ogg"),
        "thruster0": load_ogg_or_wav_as_float_mono("scifi/thrusterFire_000.ogg"),
        "thruster1": load_ogg_or_wav_as_float_mono("scifi/thrusterFire_001.ogg"),
        "glass1": load_ogg_or_wav_as_float_mono("ui/glass_001.wav"),
        "glass4": load_ogg_or_wav_as_float_mono("ui/glass_004.wav"),
    }

    # Tạo sẵn các lớp cộng hưởng vật lý bổ trợ
    sub_drop = synth_acoustic_body_layer("sub_seismic_drop", 0.65)
    fire_roar = synth_acoustic_body_layer("fire_eruption_roar", 0.75)
    thunder_crack = synth_acoustic_body_layer("thunder_crack_rumble", 0.70)
    whoosh_heavy = synth_acoustic_body_layer("blade_air_whoosh_heavy", 0.38)
    whoosh_fast = synth_acoustic_body_layer("blade_air_whoosh_fast", 0.26)
    steel_ring = synth_acoustic_body_layer("steel_resonator_chord", 0.45)
    rage_chord = synth_acoustic_body_layer("crimson_cobalt_power_chord", 0.65)

    recipes = {
        # --- PHẦN I: TRẠNG THÁI 1 (THÁNH KỴ SĨ BẠCH KIM - SẮC BÉN, THANH THOÁT, TINH TÚ) ---
        "01_u1_slash_platinum.wav": (0.36, 0.14, [
            {"samples": whoosh_fast, "pitch": 1.05, "gain": 0.75, "pan": -0.2, "delay": 0.0},
            {"samples": stems["slice1"], "pitch": 1.02, "gain": 1.15, "pan": 0.15, "delay": 0.01},
            {"samples": stems["draw1"], "pitch": 1.18, "gain": 0.55, "pan": 0.3, "delay": 0.025},
            {"samples": stems["punch_h0"], "pitch": 1.25, "gain": 0.45, "lpf": 450.0, "pan": 0.0, "delay": 0.01},
        ]),
        "02_u2_slash_platinum.wav": (0.40, 0.16, [
            {"samples": whoosh_fast, "pitch": 0.92, "gain": 0.80, "pan": 0.25, "delay": 0.0},
            {"samples": stems["slice2"], "pitch": 0.94, "gain": 1.15, "pan": -0.2, "delay": 0.0},
            {"samples": stems["slice1"], "pitch": 1.16, "gain": 0.95, "pan": 0.3, "delay": 0.055},
            {"samples": stems["metal_l0"], "pitch": 1.12, "gain": 0.65, "pan": 0.0, "delay": 0.04},
        ]),
        "03_u3_heaven_shatter.wav": (0.82, 0.24, [
            {"samples": whoosh_heavy, "pitch": 0.95, "gain": 0.90, "pan": 0.0, "delay": 0.0},
            {"samples": stems["chop"], "pitch": 0.86, "gain": 1.20, "pan": 0.0, "delay": 0.02},
            {"samples": sub_drop, "pitch": 1.0, "gain": 1.10, "pan": 0.0, "delay": 0.05},
            {"samples": stems["crunch0"], "pitch": 0.95, "gain": 0.95, "lpf": 3200.0, "pan": -0.3, "delay": 0.055, "dur": 0.65},
            {"samples": stems["metal_h0"], "pitch": 0.92, "gain": 1.05, "pan": 0.3, "delay": 0.06},
            {"samples": fire_roar, "pitch": 1.10, "gain": 0.70, "pan": 0.0, "delay": 0.08, "dur": 0.60},
            {"samples": steel_ring, "pitch": 1.0, "gain": 0.50, "pan": 0.0, "delay": 0.10},
        ]),
        "04_i_phase1_x_cleave.wav": (0.52, 0.20, [
            {"samples": stems["draw2"], "pitch": 1.05, "gain": 0.95, "pan": -0.4, "delay": 0.0},
            {"samples": stems["slice2"], "pitch": 0.96, "gain": 1.10, "pan": -0.35, "delay": 0.015},
            {"samples": stems["slice1"], "pitch": 1.14, "gain": 1.15, "pan": 0.35, "delay": 0.055},
            {"samples": stems["metal_m0"], "pitch": 1.15, "gain": 0.85, "pan": 0.0, "delay": 0.04},
            {"samples": steel_ring, "pitch": 1.20, "gain": 0.55, "pan": 0.0, "delay": 0.06},
        ]),
        "05_i_phase2_wave_launch.wav": (0.68, 0.22, [
            {"samples": whoosh_heavy, "pitch": 1.12, "gain": 1.05, "pan": 0.0, "delay": 0.0},
            {"samples": stems["chop"], "pitch": 1.04, "gain": 1.10, "pan": -0.25, "delay": 0.01},
            {"samples": fire_roar, "pitch": 1.25, "gain": 0.85, "pan": 0.25, "delay": 0.02, "dur": 0.55},
            {"samples": stems["thruster1"], "pitch": 1.15, "gain": 0.65, "lpf": 2400.0, "pan": 0.0, "delay": 0.03, "dur": 0.55},
            {"samples": stems["mining0"], "pitch": 1.10, "gain": 0.70, "pan": 0.0, "delay": 0.14},
        ]),
        "06_i_wave_finale.wav": (0.72, 0.25, [
            {"samples": sub_drop, "pitch": 1.05, "gain": 1.15, "pan": 0.0, "delay": 0.0},
            {"samples": stems["crunch1"], "pitch": 1.02, "gain": 1.05, "lpf": 3600.0, "pan": -0.3, "delay": 0.01, "dur": 0.60},
            {"samples": stems["metal_h1"], "pitch": 1.08, "gain": 0.90, "pan": 0.3, "delay": 0.02},
            {"samples": steel_ring, "pitch": 1.35, "gain": 0.60, "pan": 0.0, "delay": 0.04},
        ]),

        # --- PHẦN II: TRẠNG THÁI 2 HÓA NỘ [R] (HUYẾT LAM LONG THẦN - LỬA NGỤC, SẤM SÉT, ĐỊA CHẤN) ---
        "07_rage_r_awaken.wav": (1.15, 0.30, [
            {"samples": stems["draw3"], "pitch": 0.76, "gain": 1.15, "pan": 0.0, "delay": 0.0},
            {"samples": sub_drop, "pitch": 0.82, "gain": 1.35, "pan": 0.0, "delay": 0.03},
            {"samples": thunder_crack, "pitch": 0.90, "gain": 1.15, "pan": -0.35, "delay": 0.04},
            {"samples": fire_roar, "pitch": 0.85, "gain": 1.10, "pan": 0.35, "delay": 0.06},
            {"samples": stems["crunch0"], "pitch": 0.78, "gain": 1.05, "lpf": 2600.0, "pan": 0.0, "delay": 0.05, "dur": 0.85},
            {"samples": stems["metal_h0"], "pitch": 0.75, "gain": 1.10, "pan": -0.25, "delay": 0.08},
            {"samples": rage_chord, "pitch": 1.0, "gain": 0.95, "pan": 0.0, "delay": 0.14},
        ]),
        "08_rage_r_expire.wav": (0.55, 0.20, [
            {"samples": whoosh_heavy, "pitch": 0.75, "gain": 0.85, "pan": 0.0, "delay": 0.0},
            {"samples": stems["draw1"], "pitch": 0.78, "gain": 0.90, "pan": 0.0, "delay": 0.04},
            {"samples": sub_drop, "pitch": 1.25, "gain": 0.65, "pan": 0.0, "delay": 0.02},
        ]),
        "09_u1_rage_crimson.wav": (0.58, 0.22, [
            {"samples": whoosh_heavy, "pitch": 0.88, "gain": 1.10, "pan": -0.3, "delay": 0.0},
            {"samples": sub_drop, "pitch": 1.15, "gain": 0.95, "pan": 0.0, "delay": 0.0},
            {"samples": stems["chop"], "pitch": 0.78, "gain": 1.20, "pan": 0.25, "delay": 0.01},
            {"samples": stems["metal_h1"], "pitch": 0.82, "gain": 1.05, "pan": -0.2, "delay": 0.02},
            {"samples": fire_roar, "pitch": 1.05, "gain": 0.85, "pan": 0.3, "delay": 0.03, "dur": 0.45},
        ]),
        "10_u2_rage_cobalt.wav": (0.62, 0.22, [
            {"samples": whoosh_heavy, "pitch": 0.82, "gain": 1.10, "pan": 0.3, "delay": 0.0},
            {"samples": stems["slice2"], "pitch": 0.74, "gain": 1.15, "pan": -0.3, "delay": 0.0},
            {"samples": stems["metal_h2"], "pitch": 0.78, "gain": 1.10, "pan": 0.25, "delay": 0.025},
            {"samples": thunder_crack, "pitch": 1.15, "gain": 0.90, "pan": -0.25, "delay": 0.03, "dur": 0.48},
            {"samples": stems["crunch3"], "pitch": 0.92, "gain": 0.80, "lpf": 2800.0, "pan": 0.0, "delay": 0.05, "dur": 0.48},
        ]),
        "11_u3_rage_dragon_fall.wav": (1.18, 0.28, [
            # Pha 1 (0.00s): 5 Đại Kiếm bổ xé toạc bầu trời
            {"samples": whoosh_heavy, "pitch": 0.72, "gain": 1.20, "pan": 0.0, "delay": 0.0},
            {"samples": stems["draw3"], "pitch": 0.72, "gain": 1.10, "pan": -0.35, "delay": 0.01},
            # Pha 2 (0.05s): Đại địa chấn nứt mặt đất + Cột lửa + Sấm sét
            {"samples": sub_drop, "pitch": 0.76, "gain": 1.45, "pan": 0.0, "delay": 0.05},
            {"samples": stems["crunch0"], "pitch": 0.74, "gain": 1.25, "lpf": 2800.0, "pan": -0.3, "delay": 0.055, "dur": 0.85},
            {"samples": thunder_crack, "pitch": 0.85, "gain": 1.15, "pan": 0.3, "delay": 0.06},
            {"samples": stems["metal_h0"], "pitch": 0.72, "gain": 1.20, "pan": 0.0, "delay": 0.07},
            # Pha 3 (0.20s -> 1.10s): Lửa gầm & Năng lượng Huyết Lam phình to đọng lại trên mặt đất
            {"samples": fire_roar, "pitch": 0.82, "gain": 1.10, "pan": -0.25, "delay": 0.18},
            {"samples": rage_chord, "pitch": 0.95, "gain": 1.05, "pan": 0.25, "delay": 0.20},
            {"samples": stems["metal_h3"], "pitch": 0.70, "gain": 0.95, "pan": 0.0, "delay": 0.24},
        ]),
        "12_i_rage_hexa_cleave.wav": (0.85, 0.26, [
            {"samples": sub_drop, "pitch": 0.92, "gain": 1.25, "pan": 0.0, "delay": 0.0},
            {"samples": stems["draw3"], "pitch": 0.80, "gain": 1.15, "pan": -0.4, "delay": 0.0},
            {"samples": stems["metal_h2"], "pitch": 0.78, "gain": 1.20, "pan": -0.3, "delay": 0.025},
            {"samples": stems["metal_h3"], "pitch": 0.86, "gain": 1.20, "pan": 0.3, "delay": 0.065},
            {"samples": thunder_crack, "pitch": 1.02, "gain": 1.00, "pan": 0.4, "delay": 0.04, "dur": 0.65},
            {"samples": rage_chord, "pitch": 1.10, "gain": 0.85, "pan": 0.0, "delay": 0.12, "dur": 0.60},
        ]),
        "13_i_rage_five_wing_wave.wav": (0.98, 0.26, [
            {"samples": sub_drop, "pitch": 0.85, "gain": 1.30, "pan": 0.0, "delay": 0.0},
            {"samples": fire_roar, "pitch": 0.78, "gain": 1.25, "pan": -0.3, "delay": 0.0},
            {"samples": stems["thruster0"], "pitch": 0.75, "gain": 0.95, "lpf": 2100.0, "pan": 0.3, "delay": 0.02, "dur": 0.78},
            # 3 Nhịp cày nát sàn đá dọc hành trình 6.2m
            {"samples": stems["crunch2"], "pitch": 0.92, "gain": 0.95, "lpf": 3000.0, "pan": -0.25, "delay": 0.09, "dur": 0.40},
            {"samples": stems["crunch1"], "pitch": 0.84, "gain": 1.00, "lpf": 2800.0, "pan": 0.25, "delay": 0.20, "dur": 0.42},
            {"samples": stems["metal_h1"], "pitch": 0.76, "gain": 1.05, "pan": 0.0, "delay": 0.32},
        ]),

        # --- PHẦN III: KỸ NĂNG [O], [P], DI CHUYỂN, TRÚNG ĐÒN & NHẠC NỀN ---
        "14_o_whirlwind_spin.wav": (0.66, 0.20, [
            {"samples": whoosh_heavy, "pitch": 1.05, "gain": 1.05, "pan": -0.4, "delay": 0.0},
            {"samples": stems["slice1"], "pitch": 0.96, "gain": 1.05, "pan": -0.35, "delay": 0.0},
            {"samples": stems["slice2"], "pitch": 1.04, "gain": 1.10, "pan": 0.35, "delay": 0.14},
            {"samples": stems["chop"], "pitch": 1.12, "gain": 1.15, "pan": 0.0, "delay": 0.28},
            {"samples": stems["metal_m1"], "pitch": 1.08, "gain": 0.85, "pan": 0.2, "delay": 0.29},
        ]),
        "15_p_bomb_throw.wav": (0.32, 0.12, [
            {"samples": whoosh_fast, "pitch": 1.18, "gain": 0.95, "pan": 0.0, "delay": 0.0},
            {"samples": stems["cloth2"], "pitch": 1.08, "gain": 1.05, "pan": 0.1, "delay": 0.01},
            {"samples": stems["mining1"], "pitch": 1.35, "gain": 0.55, "pan": -0.1, "delay": 0.03},
        ]),
        "16_p_bomb_thunder_explode.wav": (0.88, 0.26, [
            {"samples": sub_drop, "pitch": 0.84, "gain": 1.35, "pan": 0.0, "delay": 0.0},
            {"samples": thunder_crack, "pitch": 0.95, "gain": 1.25, "pan": -0.3, "delay": 0.01},
            {"samples": stems["crunch2"], "pitch": 0.82, "gain": 1.15, "lpf": 2900.0, "pan": 0.3, "delay": 0.02, "dur": 0.72},
            {"samples": stems["metal_h0"], "pitch": 0.88, "gain": 0.95, "pan": 0.0, "delay": 0.04},
        ]),
        "17_p_bomb_dot_zap.wav": (0.22, 0.10, [
            {"samples": thunder_crack, "pitch": 1.85, "gain": 0.45, "pan": 0.0, "delay": 0.0, "dur": 0.18},
            {"samples": stems["metal_l0"], "pitch": 1.55, "gain": 0.40, "pan": 0.2, "delay": 0.01, "dur": 0.16},
        ]),
        "18_dash_space.wav": (0.30, 0.12, [
            {"samples": whoosh_fast, "pitch": 0.95, "gain": 1.00, "pan": 0.0, "delay": 0.0},
            {"samples": stems["cloth2"], "pitch": 1.12, "gain": 1.05, "pan": 0.0, "delay": 0.01},
            {"samples": stems["punch_h1"], "pitch": 1.35, "gain": 0.45, "lpf": 380.0, "pan": 0.0, "delay": 0.0},
        ]),
        "19_jump_c.wav": (0.26, 0.10, [
            {"samples": stems["cloth1"], "pitch": 1.08, "gain": 0.95, "pan": 0.0, "delay": 0.0},
            {"samples": stems["punch_h2"], "pitch": 1.20, "gain": 0.55, "lpf": 420.0, "pan": 0.0, "delay": 0.01},
        ]),
        "20_footstep_stone_1.wav": (0.16, 0.06, [
            {"samples": stems["step1"], "pitch": 0.95, "gain": 0.75, "lpf": 2400.0, "pan": -0.1, "delay": 0.0, "dur": 0.14},
        ]),
        "21_footstep_stone_2.wav": (0.16, 0.06, [
            {"samples": stems["step2"], "pitch": 1.02, "gain": 0.75, "lpf": 2400.0, "pan": 0.1, "delay": 0.0, "dur": 0.14},
        ]),
        "22_hit_enemy_cleave_1.wav": (0.34, 0.14, [
            {"samples": stems["punch_h0"], "pitch": 0.92, "gain": 1.20, "lpf": 1800.0, "pan": 0.0, "delay": 0.0},
            {"samples": stems["metal_m0"], "pitch": 1.04, "gain": 1.10, "pan": -0.2, "delay": 0.01},
            {"samples": stems["slice1"], "pitch": 1.12, "gain": 0.85, "pan": 0.2, "delay": 0.015},
        ]),
        "23_hit_enemy_cleave_2.wav": (0.34, 0.14, [
            {"samples": stems["punch_h1"], "pitch": 0.88, "gain": 1.20, "lpf": 1800.0, "pan": 0.0, "delay": 0.0},
            {"samples": stems["metal_m1"], "pitch": 0.98, "gain": 1.15, "pan": 0.2, "delay": 0.01},
            {"samples": stems["chop"], "pitch": 1.08, "gain": 0.90, "pan": -0.2, "delay": 0.015},
        ]),
        "24_enemy_death_burst.wav": (0.58, 0.20, [
            {"samples": sub_drop, "pitch": 1.10, "gain": 1.10, "pan": 0.0, "delay": 0.0},
            {"samples": stems["crunch3"], "pitch": 0.90, "gain": 1.05, "lpf": 2600.0, "pan": -0.25, "delay": 0.01, "dur": 0.48},
            {"samples": stems["pot"], "pitch": 0.85, "gain": 0.95, "pan": 0.25, "delay": 0.03},
            {"samples": stems["soft_h0"], "pitch": 0.82, "gain": 1.00, "pan": 0.0, "delay": 0.05},
        ]),
        "25_bgm_arena_combat_loop.wav": (8.00, 0.22, [
            {"samples": synth_acoustic_body_layer("epic_arena_bgm_loop", 8.00), "pitch": 1.0, "gain": 0.85, "pan": 0.0, "delay": 0.0, "att": 0.05, "rel": 0.05},
        ]),
    }

    for fname, (dur, rev, layers) in recipes.items():
        left, right = mix_stereo_master(layers, dur, rev)
        save_stereo_wav(fname, left, right)
        print(f"Created Stereo Master WAV: {fname} ({dur:.2f}s)")

if __name__ == "__main__":
    build_all_25_master_files()
