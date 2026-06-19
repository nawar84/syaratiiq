import { useWindowDimensions } from 'react-native';

const MOBILE_MAX = 767;
const TABLET_MAX = 1023;

export type LayoutTier = 'mobile' | 'tablet' | 'desktop';

export function useResponsiveLayout() {
  const { width, height } = useWindowDimensions();

  const tier: LayoutTier =
    width <= MOBILE_MAX ? 'mobile' : width <= TABLET_MAX ? 'tablet' : 'desktop';

  /** Same formula as Flutter `HomeScreen`: (width / 430).clamp(0.9, 1.2) */
  const scale = Math.min(Math.max(width / 430, 0.9), tier === 'desktop' ? 1.15 : 1.2);

  const contentMaxWidth = tier === 'desktop' ? 1200 : tier === 'tablet' ? 860 : width;

  const horizontalPadding = tier === 'desktop' ? 32 : tier === 'tablet' ? 24 : 14 * scale;

  const heroHeight =
    tier === 'desktop' ? Math.min(340, height * 0.38) : tier === 'tablet' ? 260 * scale : 230 * scale;

  return {
    width,
    height,
    tier,
    scale,
    contentMaxWidth,
    horizontalPadding,
    heroHeight,
    isDesktop: tier === 'desktop',
    isTablet: tier === 'tablet',
    isMobile: tier === 'mobile',
  };
}
