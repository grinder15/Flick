use super::constants::*;
use super::types::*;
use crate::uac2::error::Uac2Error;

#[derive(Clone)]
pub struct DescriptorIter<'a> {
    data: &'a [u8],
    pos: usize,
}

impl<'a> DescriptorIter<'a> {
    pub fn new(data: &'a [u8]) -> Self {
        Self { data, pos: 0 }
    }
}

impl<'a> Iterator for DescriptorIter<'a> {
    type Item = &'a [u8];

    fn next(&mut self) -> Option<Self::Item> {
        if self.pos >= self.data.len() || self.data.len() - self.pos < 2 {
            return None;
        }
        let len = self.data[self.pos] as usize;
        if len == 0 || self.pos + len > self.data.len() {
            return None;
        }
        let slice = &self.data[self.pos..self.pos + len];
        self.pos += len;
        Some(slice)
    }
}

fn require_len(data: &[u8], min: usize) -> Result<(), Uac2Error> {
    if data.len() < min {
        return Err(Uac2Error::InvalidDescriptor(format!(
            "expected at least {} bytes, got {}",
            min,
            data.len()
        )));
    }
    Ok(())
}

fn read_u16_le(data: &[u8], offset: usize) -> u16 {
    u16::from_le_bytes([data[offset], data[offset + 1]])
}

fn read_u32_le(data: &[u8], offset: usize) -> u32 {
    u32::from_le_bytes([
        data[offset],
        data[offset + 1],
        data[offset + 2],
        data[offset + 3],
    ])
}

pub fn parse_iad(data: &[u8]) -> Result<Iad, Uac2Error> {
    const IAD_LEN: usize = 8;
    require_len(data, IAD_LEN)?;
    if data[1] != USB_DT_INTERFACE_ASSOCIATION {
        return Err(Uac2Error::InvalidDescriptor("not an IAD".to_string()));
    }
    Ok(Iad {
        b_first_interface: data[2],
        b_interface_count: data[3],
        b_function_class: data[4],
        b_function_sub_class: data[5],
        b_function_protocol: data[6],
        i_function: data[7],
    })
}

pub fn parse_ac_interface_header(data: &[u8]) -> Result<AcInterfaceHeader, Uac2Error> {
    const HEADER_LEN: usize = 9;
    require_len(data, HEADER_LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_AC_HEADER {
        return Err(Uac2Error::InvalidDescriptor("not CS_AC header".to_string()));
    }
    Ok(AcInterfaceHeader {
        bcd_adc: read_u16_le(data, 3),
        b_category: data[5],
        w_total_length: read_u16_le(data, 6),
        bm_controls: read_u16_le(data, 8),
    })
}

pub fn parse_input_terminal(data: &[u8]) -> Result<InputTerminal, Uac2Error> {
    const LEN: usize = 15;
    require_len(data, LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_INPUT_TERMINAL {
        return Err(Uac2Error::InvalidDescriptor("not input terminal".to_string()));
    }
    Ok(InputTerminal {
        b_terminal_id: data[3],
        w_terminal_type: read_u16_le(data, 4),
        b_assoc_terminal: data[6],
        b_c_source_id: data[7],
        b_nr_channels: read_u16_le(data, 8),
        w_channel_config: read_u32_le(data, 10),
        i_terminal: data[14],
    })
}

pub fn parse_output_terminal(data: &[u8]) -> Result<OutputTerminal, Uac2Error> {
    const LEN: usize = 9;
    require_len(data, LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_OUTPUT_TERMINAL {
        return Err(Uac2Error::InvalidDescriptor("not output terminal".to_string()));
    }
    Ok(OutputTerminal {
        b_terminal_id: data[3],
        w_terminal_type: read_u16_le(data, 4),
        b_assoc_terminal: data[6],
        b_source_id: data[7],
        i_terminal: data[8],
    })
}

pub fn parse_feature_unit(data: &[u8]) -> Result<FeatureUnit, Uac2Error> {
    const MIN_LEN: usize = 7;
    require_len(data, MIN_LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_FEATURE_UNIT {
        return Err(Uac2Error::InvalidDescriptor("not feature unit".to_string()));
    }
    let len = data[0] as usize;
    if len < MIN_LEN || (len - 7) % 4 != 0 {
        return Err(Uac2Error::InvalidDescriptor(
            "invalid feature unit length".to_string(),
        ));
    }
    let n = (len - 7) / 4;
    require_len(data, len)?;
    let bma_controls: Vec<u32> = (0..n).map(|i| read_u32_le(data, 7 + i * 4)).collect();
    Ok(FeatureUnit {
        b_unit_id: data[3],
        b_source_id: data[4],
        b_control_size: data[5],
        bma_controls,
    })
}

pub fn parse_as_interface_general(data: &[u8]) -> Result<AsInterfaceGeneral, Uac2Error> {
    const LEN: usize = 7;
    require_len(data, LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_AS_GENERAL {
        return Err(Uac2Error::InvalidDescriptor("not AS general".to_string()));
    }
    Ok(AsInterfaceGeneral {
        b_terminal_link: data[3],
        b_delay: data[4],
        w_format_tag: read_u16_le(data, 5),
    })
}

pub fn parse_format_type_i(data: &[u8]) -> Result<FormatTypeI, Uac2Error> {
    const MIN_LEN: usize = 8;
    require_len(data, MIN_LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_FORMAT_TYPE || data[3] != UAC2_FORMAT_TYPE_I
    {
        return Err(Uac2Error::InvalidDescriptor("not format type I".to_string()));
    }
    let b_sam_freq_type = data[6];
    let mut sample_rates: Vec<u32> = Vec::new();
    if b_sam_freq_type == 0 {
        if data.len() >= 10 {
            sample_rates.push(read_u32_le(data, 7));
        }
    } else {
        let num_rates = b_sam_freq_type as usize;
        require_len(data, 7 + num_rates * 6)?;
        for i in 0..num_rates {
            sample_rates.push(read_u32_le(data, 7 + i * 6));
        }
    }
    Ok(FormatTypeI {
        b_subslot_size: data[4],
        b_bit_resolution: data[5],
        b_sam_freq_type,
        sample_rates,
    })
}

pub fn parse_format_type_ii(data: &[u8]) -> Result<FormatTypeII, Uac2Error> {
    const MIN_LEN: usize = 10;
    require_len(data, MIN_LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_FORMAT_TYPE
        || data[3] != UAC2_FORMAT_TYPE_II
    {
        return Err(Uac2Error::InvalidDescriptor("not format type II".to_string()));
    }
    let b_sam_freq_type = data[9];
    let mut sample_rates: Vec<u32> = Vec::new();
    if b_sam_freq_type == 0 {
        if data.len() >= 13 {
            sample_rates.push(read_u32_le(data, 10));
        }
    } else {
        let num_rates = b_sam_freq_type as usize;
        require_len(data, 10 + num_rates * 6)?;
        for i in 0..num_rates {
            sample_rates.push(read_u32_le(data, 10 + i * 6));
        }
    }
    Ok(FormatTypeII {
        w_max_bit_rate: read_u16_le(data, 4),
        w_samples_per_frame: read_u16_le(data, 6),
        b_sam_freq_type,
        sample_rates,
    })
}

pub fn parse_format_type_iii(data: &[u8]) -> Result<FormatTypeIII, Uac2Error> {
    const LEN: usize = 6;
    require_len(data, LEN)?;
    if data[1] != USB_DT_CS_INTERFACE || data[2] != UAC2_FORMAT_TYPE
        || data[3] != UAC2_FORMAT_TYPE_III
    {
        return Err(Uac2Error::InvalidDescriptor("not format type III".to_string()));
    }
    Ok(FormatTypeIII {
        b_subslot_size: data[4],
        b_bit_resolution: data[5],
    })
}
