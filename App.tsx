import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useState } from 'react';
import {
  Image,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { BrandLogoBadge } from './components/BrandLogoBadge';
import { BottomNavBar } from './components/BottomNavBar';
import { useResponsiveLayout } from './hooks/useResponsiveLayout';
import { MetallicSilverText } from './MetallicSilverText';
import { colors } from './theme/colors';

const heroImage = require('./mobile/assets/images/hero_toyota_land_cruiser.png');

const brands = [
  { name: 'Toyota', logo: require('./mobile/assets/brands/png/toyota.png') },
  { name: 'Hyundai', logo: require('./mobile/assets/brands/png/hyundai.png') },
  { name: 'Land Rover', logo: require('./mobile/assets/brands/png/land_rover.png') },
  { name: 'BMW', logo: require('./mobile/assets/brands/png/bmw.png') },
  { name: 'Mercedes', logo: require('./mobile/assets/brands/png/mercedes.png') },
  { name: 'Kia', logo: require('./mobile/assets/brands/png/kia.png') },
  { name: 'Cadillac', logo: require('./mobile/assets/brands/png/cadillac.png') },
  { name: 'Changan', logo: require('./mobile/assets/brands/png/changan.png') },
] as const;

const stats = [
  { value: '+10,000', label: 'سيارة' },
  { value: '+1,000', label: 'معرض' },
  { value: '18', label: 'محافظة' },
] as const;

type Tab = 'home' | 'search' | 'account';

export default function App() {
  const [activeTab, setActiveTab] = useState<Tab>('home');
  const layout = useResponsiveLayout();
  const { width } = useWindowDimensions();
  const { scale, contentMaxWidth, horizontalPadding, heroHeight, isDesktop } = layout;

  return (
    <View style={styles.root}>
      <LinearGradient
        colors={[colors.backgroundTop, colors.backgroundBottom]}
        style={StyleSheet.absoluteFill}
      />

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[
          styles.scrollContent,
          {
            maxWidth: contentMaxWidth,
            paddingHorizontal: horizontalPadding,
            paddingBottom: 96,
            width: '100%',
            alignSelf: 'center',
          },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={[styles.header, { marginTop: 12 * scale }]}>
          <MetallicSilverText style={[styles.logo, { fontSize: 28 * scale }]}>
            سياراتي IQ
          </MetallicSilverText>
          <View style={styles.headerIcons}>
            <Ionicons name="notifications-outline" size={28 * scale} color={colors.iconMuted} />
            <Ionicons name="person-circle-outline" size={30 * scale} color={colors.iconMuted} />
          </View>
        </View>

        <Image
          source={heroImage}
          style={[
            styles.hero,
            {
              height: heroHeight,
              marginTop: 12 * scale,
              maxWidth: isDesktop ? 920 : width - horizontalPadding * 2,
            },
          ]}
          resizeMode="contain"
        />

        <View style={[styles.statsRow, { marginTop: 12 * scale, gap: 8 * scale }]}>
          {stats.map((stat) => (
            <View
              key={stat.label}
              style={[
                styles.statCard,
                {
                  borderRadius: 16 * scale,
                  paddingVertical: 12 * scale,
                },
              ]}
            >
              <MetallicSilverText style={[styles.statValue, { fontSize: 20 * scale }]}>
                {stat.value}
              </MetallicSilverText>
              <MetallicSilverText style={[styles.statLabel, { fontSize: 14 * scale }]}>
                {stat.label}
              </MetallicSilverText>
            </View>
          ))}
        </View>

        <MetallicSilverText
          headline
          style={[
            styles.headline,
            {
              fontSize: (isDesktop ? 44 : 40) * scale,
              lineHeight: (isDesktop ? 48 : 44) * scale,
              marginTop: 18 * scale,
            },
          ]}
        >
          {'أكبر منصة معارض سيارات\nفي العراق'}
        </MetallicSilverText>

        <MetallicSilverText
          style={[
            styles.subHeadline,
            {
              fontSize: 17 * scale,
              marginTop: 8 * scale,
            },
          ]}
        >
          اعرض سياراتك ووصل الى آلاف المشترين
        </MetallicSilverText>

        <MetallicSilverText
          style={[
            styles.brandsTitle,
            {
              fontSize: 22 * scale,
              marginTop: 14 * scale,
            },
          ]}
        >
          أشهر الماركات
        </MetallicSilverText>
        <MetallicSilverText
          style={[
            styles.brandsSubtitle,
            {
              fontSize: 14 * scale,
              marginTop: 4 * scale,
            },
          ]}
        >
          تصفح حسب العلامة التجارية
        </MetallicSilverText>

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={[
            styles.brandsRow,
            {
              paddingVertical: 14 * scale,
              gap: 12 * scale,
              paddingHorizontal: 4 * scale,
            },
          ]}
          style={{ marginHorizontal: -4 * scale }}
        >
          {brands.map((brand) => (
            <BrandLogoBadge key={brand.name} name={brand.name} logo={brand.logo} scale={scale} />
          ))}
        </ScrollView>
      </ScrollView>

      <View style={styles.navDock}>
        <BottomNavBar
          activeTab={activeTab}
          onHome={() => setActiveTab('home')}
          onAccount={() => setActiveTab('account')}
          scale={scale}
          maxWidth={contentMaxWidth}
        />
      </View>

      <StatusBar style="light" />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.scaffold,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerIcons: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  logo: {
    fontWeight: '800',
  },
  hero: {
    width: '100%',
    alignSelf: 'center',
  },
  statsRow: {
    flexDirection: 'row',
  },
  statCard: {
    flex: 1,
    backgroundColor: colors.statFill,
    borderWidth: 1,
    borderColor: colors.statBorder,
    alignItems: 'center',
  },
  statValue: {
    fontWeight: '800',
    textAlign: 'center',
  },
  statLabel: {
    fontWeight: '500',
    textAlign: 'center',
    marginTop: 2,
  },
  headline: {
    fontWeight: '900',
    textAlign: 'center',
  },
  subHeadline: {
    fontWeight: '500',
    textAlign: 'center',
  },
  brandsTitle: {
    fontWeight: '800',
    textAlign: 'center',
  },
  brandsSubtitle: {
    fontWeight: '500',
    textAlign: 'center',
  },
  brandsRow: {
    flexDirection: 'row-reverse',
    alignItems: 'flex-start',
  },
  navDock: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
  },
});
