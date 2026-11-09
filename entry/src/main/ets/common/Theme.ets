import { deviceInfo } from '@kit.BasicServicesKit';

// Dark on every device: a watch has no light theme, and an OLED screen shows black as off.
export const BACKGROUND = '#000000';
export const TEXT = '#FFFFFF';
export const SECONDARY_TEXT = '#A1A1A6';
export const ERROR_TEXT = '#FF8A80';
export const CHIP = '#2C2C2E';
export const CHIP_SELECTED = '#2F5D8A';
export const DIVIDER = '#38383A';
export const CODE_BACKGROUND = '#1C1C1E';

export const ROUND: boolean = deviceInfo.deviceType === deviceInfo.DeviceTypes.TYPE_WEARABLE;
// A round screen clips the corners: at 48vp from the top of a 233vp circle the screen is wider than the content area
// left by the 12% side padding.
export const SIDE_PADDING: Length = ROUND ? '12%' : 16;
export const END_PADDING: number = ROUND ? 48 : 16;
