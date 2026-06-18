import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import { Image, Pressable, SafeAreaView, StyleSheet, View } from 'react-native';
import { MetallicSilverText } from './MetallicSilverText';

const topBrands = ['TOYOTA', 'HYUNDAI', 'LAND', 'NISSAN'];
const bottomBrands = ['CAR', 'MG', 'BMW', 'BENZ'];

export default function App() {
  const [activeTab, setActiveTab] = useState<'home' | 'search' | 'account'>('home');

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.phoneShell}>
        <View style={styles.topGlow} />

        <View style={styles.header}>
          <View style={styles.headerIcons}>
            <Ionicons name="person-circle-outline" size={31} color="#e6ecff" />
            <Ionicons name="notifications-outline" size={25} color="#e6ecff" />
          </View>
          <MetallicSilverText style={styles.logo}>سيارتي IQ</MetallicSilverText>
        </View>

        <Image
          source={{
            uri: 'https://images.unsplash.com/photo-1705680393131-f6f1695d2f68?auto=format&fit=crop&w=1200&q=80',
          }}
          style={styles.carImage}
          resizeMode="cover"
        />

        <View style={styles.statsRow}>
          <View style={styles.glassCard}>
            <MetallicSilverText style={styles.glassValue}>18</MetallicSilverText>
            <MetallicSilverText style={styles.glassLabel}>محافظة</MetallicSilverText>
          </View>
          <View style={styles.glassCard}>
            <MetallicSilverText style={styles.glassValue}>+1,000</MetallicSilverText>
            <MetallicSilverText style={styles.glassLabel}>معرض</MetallicSilverText>
          </View>
          <View style={styles.glassCard}>
            <MetallicSilverText style={styles.glassValue}>+10,000</MetallicSilverText>
            <MetallicSilverText style={styles.glassLabel}>سيارة</MetallicSilverText>
          </View>
        </View>

        <View style={styles.headlineWrap}>
          <MetallicSilverText headline style={styles.headline}>
            أكبر منصة معارض سيارات في العراق
          </MetallicSilverText>
        </View>
        <MetallicSilverText style={styles.subHeadline}>اعرض سياراتك ووصل إلى الآف المشترين</MetallicSilverText>

        <View style={styles.brandRow}>
          {topBrands.map((brand) => (
            <View key={brand} style={styles.brandCircle}>
              <MetallicSilverText style={styles.brandText}>{brand}</MetallicSilverText>
            </View>
          ))}
        </View>
        <View style={styles.brandRow}>
          {bottomBrands.map((brand) => (
            <View key={brand} style={styles.brandCircle}>
              <MetallicSilverText style={styles.brandText}>{brand}</MetallicSilverText>
            </View>
          ))}
        </View>

        <View style={styles.bottomBar}>
          <Pressable style={styles.navItem} onPress={() => setActiveTab('account')}>
            <Ionicons
              name={activeTab === 'account' ? 'person' : 'person-outline'}
              size={28}
              color={activeTab === 'account' ? '#fff' : '#8591bc'}
            />
            <MetallicSilverText style={[styles.navText, activeTab === 'account' && styles.navTextActive]}>
              حسابي
            </MetallicSilverText>
          </Pressable>

          <Pressable style={styles.addButton}>
            <Ionicons name="add" size={60} color="#fff" />
          </Pressable>

          <Pressable style={styles.navItem} onPress={() => setActiveTab('home')}>
            <Ionicons
              name={activeTab === 'home' ? 'home' : 'home-outline'}
              size={28}
              color={activeTab === 'home' ? '#fff' : '#8591bc'}
            />
            <MetallicSilverText style={[styles.navText, activeTab === 'home' && styles.navTextActive]}>
              الرئيسية
            </MetallicSilverText>
          </Pressable>
        </View>
      </View>
      <StatusBar style="light" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#02091f',
    justifyContent: 'center',
    alignItems: 'center',
  },
  phoneShell: {
    width: '93%',
    maxWidth: 420,
    height: '95%',
    backgroundColor: '#040f2e',
    borderRadius: 34,
    borderWidth: 1,
    borderColor: '#1f2f59',
    overflow: 'hidden',
    paddingTop: 18,
    paddingHorizontal: 14,
  },
  topGlow: {
    position: 'absolute',
    top: -120,
    left: -80,
    right: -80,
    height: 260,
    backgroundColor: '#1542af',
    opacity: 0.35,
    borderRadius: 180,
  },
  header: {
    flexDirection: 'row-reverse',
    justifyContent: 'space-between',
    alignItems: 'center',
    zIndex: 2,
  },
  logo: {
    fontSize: 44,
    fontWeight: '800',
  },
  headerIcons: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
  },
  carImage: {
    width: '100%',
    height: 245,
    borderRadius: 18,
    marginTop: 10,
  },
  statsRow: {
    flexDirection: 'row-reverse',
    justifyContent: 'space-between',
    marginTop: -2,
  },
  glassCard: {
    width: '31.8%',
    borderRadius: 18,
    paddingVertical: 13,
    backgroundColor: 'rgba(198,212,255,0.14)',
    borderWidth: 1,
    borderColor: 'rgba(173,194,255,0.28)',
  },
  glassValue: {
    fontSize: 32,
    fontWeight: '800',
    textAlign: 'center',
  },
  glassLabel: {
    fontSize: 20,
    textAlign: 'center',
    marginTop: 2,
  },
  headlineWrap: {
    width: '100%',
    marginTop: 16,
  },
  headline: {
    fontSize: 50,
    lineHeight: 58,
    fontWeight: '900',
    textAlign: 'center',
  },
  subHeadline: {
    fontSize: 26,
    textAlign: 'center',
    marginTop: 6,
    marginBottom: 12,
  },
  brandRow: {
    flexDirection: 'row-reverse',
    justifyContent: 'space-evenly',
    marginTop: 8,
  },
  brandCircle: {
    width: 73,
    height: 73,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#0f1f4a',
    borderWidth: 1,
    borderColor: '#304f8f',
    shadowColor: '#6d86ff',
    shadowOpacity: 0.22,
    shadowRadius: 8,
  },
  brandText: {
    fontSize: 11,
    fontWeight: '700',
  },
  bottomBar: {
    position: 'absolute',
    bottom: 10,
    left: 10,
    right: 10,
    height: 114,
    borderRadius: 27,
    backgroundColor: '#121f44',
    borderWidth: 1,
    borderColor: '#2f3f72',
    flexDirection: 'row-reverse',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingTop: 17,
    paddingHorizontal: 30,
  },
  navItem: {
    alignItems: 'center',
    gap: 2,
  },
  navText: {
    fontSize: 16,
    fontWeight: '600',
  },
  navTextActive: {
    fontWeight: '800',
  },
  addButton: {
    width: 141,
    height: 141,
    marginTop: -54,
    borderRadius: 72,
    backgroundColor: '#ff9412',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 9,
    borderColor: '#141f46',
    shadowColor: '#ff8d0f',
    shadowOpacity: 0.35,
    shadowRadius: 16,
  },
});
