import { LinearGradient } from 'expo-linear-gradient';
import MaskedView from '@react-native-masked-view/masked-view';
import { StyleProp, StyleSheet, Text, TextStyle, View } from 'react-native';

type Props = {
  children: string;
  style?: StyleProp<TextStyle>;
  headline?: boolean;
};

// High-contrast metallic silver — avoids flat white appearance.
const GRADIENT = ['#707070', '#989898', '#C8C8C8', '#F0F0F0', '#B0B0B0', '#787878'] as const;
const HEADLINE_GRADIENT = [
  '#585858',
  '#808080',
  '#AAAAAA',
  '#D8D8D8',
  '#F5F5F5',
  '#C0C0C0',
  '#909090',
  '#606060',
] as const;

export function MetallicSilverText({ children, style, headline = false }: Props) {
  const colors = headline ? HEADLINE_GRADIENT : GRADIENT;

  return (
    <MaskedView
      style={styles.wrapper}
      maskElement={
        <View style={styles.maskWrap}>
          <Text style={[styles.maskText, style]}>{children}</Text>
        </View>
      }
    >
      <LinearGradient
        colors={[...colors]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradientFill}
      >
        <Text style={[styles.maskText, style, styles.hiddenText]}>{children}</Text>
      </LinearGradient>
    </MaskedView>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    alignSelf: 'stretch',
  },
  maskWrap: {
    backgroundColor: 'transparent',
  },
  maskText: {
    color: '#000000',
    textShadowColor: 'rgba(0,0,0,0.25)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  gradientFill: {
    flex: 1,
  },
  hiddenText: {
    opacity: 0,
  },
});
