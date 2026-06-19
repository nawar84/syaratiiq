import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';
import { MetallicSilverText } from '../MetallicSilverText';
import { colors } from '../theme/colors';

type Tab = 'home' | 'search' | 'account';

type Props = {
  activeTab: Tab;
  onHome: () => void;
  onAccount: () => void;
  scale: number;
  maxWidth: number;
};

export function BottomNavBar({ activeTab, onHome, onAccount, scale, maxWidth }: Props) {
  const iconSize = 24 * scale;
  const labelSize = 12 * scale;

  return (
    <View style={styles.outer}>
      <View style={[styles.bar, { maxWidth, paddingHorizontal: 24 * scale }]}>
        <Pressable style={styles.sideItem} onPress={onHome}>
          <Ionicons
            name={activeTab === 'home' ? 'home' : 'home-outline'}
            size={iconSize}
            color={activeTab === 'home' ? colors.iconActive : colors.iconInactive}
          />
          <MetallicSilverText
            style={[
              styles.label,
              { fontSize: labelSize, fontWeight: activeTab === 'home' ? '700' : '500' },
            ]}
          >
            الرئيسية
          </MetallicSilverText>
        </Pressable>

        <View style={styles.spacer} />

        <Pressable style={styles.sideItem} onPress={onAccount}>
          <Ionicons
            name={activeTab === 'account' ? 'person' : 'person-outline'}
            size={iconSize}
            color={activeTab === 'account' ? colors.iconActive : colors.iconInactive}
          />
          <MetallicSilverText
            style={[
              styles.label,
              { fontSize: labelSize, fontWeight: activeTab === 'account' ? '700' : '500' },
            ]}
          >
            حسابي
          </MetallicSilverText>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  outer: {
    width: '100%',
    alignItems: 'center',
    backgroundColor: colors.navBar,
    borderTopWidth: 1,
    borderTopColor: colors.navBarBorder,
  },
  bar: {
    width: '100%',
    height: 72,
    flexDirection: 'row-reverse',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sideItem: {
    alignItems: 'center',
    gap: 4,
    minWidth: 72,
  },
  label: {
    textAlign: 'center',
  },
  spacer: {
    flex: 1,
  },
});
