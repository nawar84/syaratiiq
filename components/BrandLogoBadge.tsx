import { Image, ImageSourcePropType, StyleSheet, View } from 'react-native';
import { MetallicSilverText } from '../MetallicSilverText';

type Props = {
  name: string;
  logo: ImageSourcePropType;
  scale: number;
};

export function BrandLogoBadge({ name, logo, scale }: Props) {
  const logoSize = 56 * scale;

  return (
    <View style={[styles.wrap, { width: logoSize + 16 }]}>
      <Image source={logo} style={{ width: logoSize, height: logoSize }} resizeMode="contain" />
      <MetallicSilverText style={[styles.label, { fontSize: 11 * scale, marginTop: 6 * scale }]}>
        {name}
      </MetallicSilverText>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
  },
  label: {
    fontWeight: '600',
    textAlign: 'center',
  },
});
