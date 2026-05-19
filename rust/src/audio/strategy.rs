use crate::audio::backend::BackendType;
use serde::Serialize;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum OutputStrategy {
    DapNative,
    MixerBitPerfect,
    MixerMatched,
    UsbDirect,
    ResampledFallback,
}

impl From<OutputStrategy> for BackendType {
    fn from(strategy: OutputStrategy) -> Self {
        match strategy {
            OutputStrategy::DapNative => BackendType::DapNative,
            OutputStrategy::MixerBitPerfect => BackendType::MixerBitPerfect,
            OutputStrategy::MixerMatched => BackendType::MixerMatched,
            OutputStrategy::UsbDirect => BackendType::UsbDirect,
            OutputStrategy::ResampledFallback => BackendType::ResampledFallback,
        }
    }
}

impl From<BackendType> for OutputStrategy {
    fn from(bt: BackendType) -> Self {
        match bt {
            BackendType::DapNative => OutputStrategy::DapNative,
            BackendType::MixerBitPerfect => OutputStrategy::MixerBitPerfect,
            BackendType::MixerMatched => OutputStrategy::MixerMatched,
            BackendType::UsbDirect => OutputStrategy::UsbDirect,
            BackendType::ResampledFallback => OutputStrategy::ResampledFallback,
        }
    }
}

impl OutputStrategy {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::DapNative => "dap_native",
            Self::MixerBitPerfect => "mixer_bit_perfect",
            Self::MixerMatched => "mixer_matched",
            Self::UsbDirect => "usb_direct",
            Self::ResampledFallback => "resampled_fallback",
        }
    }

    pub fn requests_passthrough(self) -> bool {
        matches!(
            self,
            Self::DapNative | Self::MixerBitPerfect | Self::UsbDirect
        )
    }
}

#[derive(Debug, Clone, Copy)]
pub struct TrackInfo {
    pub sample_rate: u32,
    pub channels: usize,
}

#[derive(Debug, Clone)]
pub struct DeviceCaps {
    pub api_level: Option<u32>,
    pub confirmed_dap_native: bool,
    pub supports_mixer_bit_perfect: bool,
    pub supports_requested_rate: bool,
    pub direct_usb_available: bool,
    pub direct_usb_verified: bool,
}

pub struct BackendCandidate {
    pub backend_type: BackendType,
    pub scorer: fn(&DeviceCaps, &TrackInfo) -> Option<u8>,
}

fn score_dap_native(device: &DeviceCaps, track: &TrackInfo) -> Option<u8> {
    if device.confirmed_dap_native && track.sample_rate > 0 && track.channels > 0 {
        Some(100)
    } else {
        None
    }
}

fn score_mixer_bit_perfect(device: &DeviceCaps, _track: &TrackInfo) -> Option<u8> {
    if device.api_level.unwrap_or_default() >= 34 && device.supports_mixer_bit_perfect {
        Some(80)
    } else {
        None
    }
}

fn score_mixer_matched(device: &DeviceCaps, track: &TrackInfo) -> Option<u8> {
    if device.supports_requested_rate && track.sample_rate > 0 && track.channels > 0 {
        Some(60)
    } else {
        None
    }
}

fn score_usb_direct(device: &DeviceCaps, _track: &TrackInfo) -> Option<u8> {
    if device.direct_usb_available && device.direct_usb_verified {
        Some(70)
    } else {
        None
    }
}

fn score_resampled_fallback(_device: &DeviceCaps, _track: &TrackInfo) -> Option<u8> {
    Some(10)
}

pub static DEFAULT_CANDIDATES: &[BackendCandidate] = &[
    BackendCandidate { backend_type: BackendType::DapNative, scorer: score_dap_native },
    BackendCandidate { backend_type: BackendType::MixerBitPerfect, scorer: score_mixer_bit_perfect },
    BackendCandidate { backend_type: BackendType::MixerMatched, scorer: score_mixer_matched },
    BackendCandidate { backend_type: BackendType::UsbDirect, scorer: score_usb_direct },
    BackendCandidate { backend_type: BackendType::ResampledFallback, scorer: score_resampled_fallback },
];

pub fn select_strategy(track: TrackInfo, device: &DeviceCaps) -> OutputStrategy {
    select_strategy_with_candidates(&track, device, DEFAULT_CANDIDATES)
}

pub fn select_strategy_with_candidates(
    track: &TrackInfo,
    device: &DeviceCaps,
    candidates: &[BackendCandidate],
) -> OutputStrategy {
    candidates
        .iter()
        .filter_map(|candidate| {
            (candidate.scorer)(device, track).map(|score| (candidate.backend_type, score))
        })
        .max_by_key(|(_, score)| *score)
        .map(|(backend_type, _)| backend_type.into())
        .unwrap_or(OutputStrategy::ResampledFallback)
}

#[cfg(test)]
mod tests {
    use super::{select_strategy, select_strategy_with_candidates, BackendCandidate, DeviceCaps, OutputStrategy, TrackInfo, DEFAULT_CANDIDATES};

    #[test]
    fn picks_mixer_bit_perfect_when_platform_supports_it() {
        let strategy = select_strategy(
            TrackInfo {
                sample_rate: 44_100,
                channels: 2,
            },
            &DeviceCaps {
                api_level: Some(34),
                confirmed_dap_native: false,
                supports_mixer_bit_perfect: true,
                supports_requested_rate: true,
                direct_usb_available: true,
                direct_usb_verified: true,
            },
        );

        assert_eq!(strategy, OutputStrategy::MixerBitPerfect);
    }

    #[test]
    fn picks_usb_direct_when_direct_path_is_only_verified_option() {
        let strategy = select_strategy(
            TrackInfo {
                sample_rate: 192_000,
                channels: 2,
            },
            &DeviceCaps {
                api_level: Some(33),
                confirmed_dap_native: false,
                supports_mixer_bit_perfect: false,
                supports_requested_rate: false,
                direct_usb_available: true,
                direct_usb_verified: true,
            },
        );

        assert_eq!(strategy, OutputStrategy::UsbDirect);
    }

    #[test]
    fn falls_back_to_resampler_when_no_exact_path_exists() {
        let strategy = select_strategy(
            TrackInfo {
                sample_rate: 44_100,
                channels: 2,
            },
            &DeviceCaps {
                api_level: Some(33),
                confirmed_dap_native: false,
                supports_mixer_bit_perfect: false,
                supports_requested_rate: false,
                direct_usb_available: false,
                direct_usb_verified: false,
            },
        );

        assert_eq!(strategy, OutputStrategy::ResampledFallback);
    }

    #[test]
    fn picks_dap_native_for_confirmed_dap_routes() {
        let strategy = select_strategy(
            TrackInfo {
                sample_rate: 192_000,
                channels: 2,
            },
            &DeviceCaps {
                api_level: Some(31),
                confirmed_dap_native: true,
                supports_mixer_bit_perfect: false,
                supports_requested_rate: false,
                direct_usb_available: false,
                direct_usb_verified: false,
            },
        );

        assert_eq!(strategy, OutputStrategy::DapNative);
    }

    #[test]
    fn custom_candidates_override_defaults() {
        fn always_mixer(_device: &DeviceCaps, _track: &TrackInfo) -> Option<u8> {
            Some(200)
        }

        let custom = vec![
            BackendCandidate { backend_type: crate::audio::backend::BackendType::MixerMatched, scorer: always_mixer },
        ];

        let strategy = select_strategy_with_candidates(
            &TrackInfo { sample_rate: 44_100, channels: 2 },
            &DeviceCaps {
                api_level: Some(34),
                confirmed_dap_native: true,
                supports_mixer_bit_perfect: true,
                supports_requested_rate: true,
                direct_usb_available: true,
                direct_usb_verified: true,
            },
            &custom,
        );

        assert_eq!(strategy, OutputStrategy::MixerMatched);
    }

    #[test]
    fn dap_native_beats_usb_direct_on_score() {
        let strategy = select_strategy(
            TrackInfo {
                sample_rate: 192_000,
                channels: 2,
            },
            &DeviceCaps {
                api_level: Some(33),
                confirmed_dap_native: true,
                supports_mixer_bit_perfect: false,
                supports_requested_rate: false,
                direct_usb_available: true,
                direct_usb_verified: true,
            },
        );

        assert_eq!(strategy, OutputStrategy::DapNative);
    }

    #[test]
    fn usb_direct_beats_mixer_matched_on_score() {
        let strategy = select_strategy(
            TrackInfo {
                sample_rate: 96_000,
                channels: 2,
            },
            &DeviceCaps {
                api_level: Some(33),
                confirmed_dap_native: false,
                supports_mixer_bit_perfect: false,
                supports_requested_rate: true,
                direct_usb_available: true,
                direct_usb_verified: true,
            },
        );

        assert_eq!(strategy, OutputStrategy::UsbDirect);
    }
}
