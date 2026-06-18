<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;

class MarketplaceSearch
{
    /** @var array<string, list<string>> */
    private const BRAND_ALIASES = [
        'Toyota' => ['تويوتا'],
        'Hyundai' => ['هيونداي', 'هونداي'],
        'BMW' => ['بي ام', 'بي ام دبليو', 'بي إم', 'bmw'],
        'Mercedes' => ['مرسيدس', 'mercedes'],
        'Kia' => ['كيا', 'kia', 'KIA'],
        'Land Rover' => ['لاند روفر', 'رنج روفر', 'land rover'],
        'Cadillac' => ['كاديلاك', 'cadillac'],
        'Changan' => ['شانجان', 'changan'],
    ];

    /** @var list<list<string>> */
    private const SYNONYM_GROUPS = [
        ['أبيض', 'white', 'White'],
        ['أسود', 'black', 'Black'],
        ['فضي', 'silver', 'Silver'],
        ['رمادي', 'gray', 'grey', 'Gray', 'Grey'],
        ['أزرق', 'blue', 'Blue'],
        ['أحمر', 'red', 'Red'],
        ['بيج', 'beige', 'Beige'],
        ['بنزين', 'petrol', 'Petrol', 'gasoline', 'Gasoline', 'gas'],
        ['ديزل', 'diesel', 'Diesel'],
        ['هجين', 'hybrid', 'Hybrid'],
        ['أوتوماتيك', 'automatic', 'Automatic', 'auto', 'Auto'],
        ['يدوي', 'manual', 'Manual'],
        ['بغداد', 'baghdad', 'Baghdad'],
        ['البصرة', 'basra', 'Basra', 'Basrah'],
        ['نينوى', 'nineveh', 'Nineveh', 'mosul', 'Mosul'],
        ['أربيل', 'erbil', 'Erbil', 'Arbil'],
        ['السليمانية', 'sulaymaniyah', 'Sulaymaniyah', 'Suleimaniya'],
        ['دهوك', 'duhok', 'Duhok', 'Dohuk'],
        ['كركوك', 'kirkuk', 'Kirkuk'],
        ['الأنبار', 'anbar', 'Anbar', 'ramadi', 'Ramadi'],
        ['بابل', 'babil', 'Babil', 'Babylon'],
        ['كربلاء', 'karbala', 'Karbala', 'Kerbala'],
        ['النجف', 'najaf', 'Najaf'],
        ['واسط', 'wasit', 'Wasit'],
        ['ديالى', 'diyala', 'Diyala'],
        ['صلاح الدين', 'salahuddin', 'Salahuddin', 'Saladin'],
        ['المثنى', 'muthanna', 'Muthanna'],
        ['ذي قار', 'dhi qar', 'Dhi Qar', 'nasiriyah', 'Nasiriyah'],
        ['ميسان', 'maysan', 'Maysan', 'Amara'],
        ['القادسية', 'qadisiyah', 'Qadisiyah', 'Diwaniyah'],
    ];

    /** @return list<string> */
    public static function splitTerms(string $text): array
    {
        $text = trim($text);
        if ($text === '') {
            return [];
        }

        $parts = preg_split('/\s+/u', $text) ?: [];

        return array_values(array_unique(array_filter(
            array_map(static fn (string $part): string => trim($part), $parts),
            static fn (string $part): bool => $part !== ''
        )));
    }

    /** @return list<string> */
    public static function collectCarSearchTerms(?string ...$inputs): array
    {
        $terms = [];

        foreach ($inputs as $input) {
            if ($input === null) {
                continue;
            }

            $terms = array_merge($terms, self::splitTerms($input));
        }

        return array_values(array_unique($terms));
    }

    public static function applyExhibitionSearch(Builder $query, string $term): void
    {
        $term = trim($term);
        if ($term === '') {
            return;
        }

        $patterns = self::likePatterns($term);
        if ($patterns === []) {
            return;
        }

        $query->where(function (Builder $outer) use ($patterns, $term): void {
            self::orWhereColumnsLike($outer, ['name', 'owner_name', 'address', 'description'], $patterns);

            $outer->orWhereHas('province', function (Builder $province) use ($patterns): void {
                $province->where(function (Builder $provinceQuery) use ($patterns): void {
                    self::orWhereColumnsLike($provinceQuery, ['name'], $patterns);
                });
            });

            $outer->orWhereHas('cars', function (Builder $cars) use ($term): void {
                $cars->where('is_active', true);
                self::applyCarSearch($cars, $term);
            });
        });
    }

    public static function applyCarSearch(Builder $query, string $term): void
    {
        $term = trim($term);
        if ($term === '') {
            return;
        }

        $patterns = self::likePatterns($term);
        if ($patterns === []) {
            return;
        }

        $brandNames = self::matchingBrandNames($term);

        $query->where(function (Builder $outer) use ($patterns, $brandNames): void {
            self::orWhereColumnsLike(
                $outer,
                ['title', 'name', 'model', 'description', 'color', 'fuel_type', 'transmission', 'damage_notes'],
                $patterns
            );

            $outer->orWhereHas('brand', function (Builder $brand) use ($patterns, $brandNames): void {
                $brand->where(function (Builder $inner) use ($patterns, $brandNames): void {
                    foreach ($patterns as $pattern) {
                        $inner->orWhereRaw('LOWER(name) LIKE ?', [mb_strtolower($pattern)]);
                    }

                    if ($brandNames !== []) {
                        $inner->orWhereIn('name', $brandNames);
                    }
                });
            });

            $outer->orWhereHas('exhibition', function (Builder $exhibition) use ($patterns): void {
                $exhibition->where(function (Builder $inner) use ($patterns): void {
                    self::orWhereColumnsLike($inner, ['name', 'address', 'description', 'owner_name'], $patterns);

                    $inner->orWhereHas('province', function (Builder $province) use ($patterns): void {
                        $province->where(function (Builder $provinceQuery) use ($patterns): void {
                            self::orWhereColumnsLike($provinceQuery, ['name'], $patterns);
                        });
                    });
                });
            });
        });
    }

    public static function applyBrandFilter(Builder $query, string $term): void
    {
        $term = trim($term);
        if ($term === '') {
            return;
        }

        $patterns = self::likePatterns($term);
        $brandNames = self::matchingBrandNames($term);

        if ($patterns === [] && $brandNames === []) {
            return;
        }

        $query->where(function (Builder $brand) use ($patterns, $brandNames): void {
            foreach ($patterns as $pattern) {
                $brand->orWhereRaw('LOWER(name) LIKE ?', [mb_strtolower($pattern)]);
            }

            if ($brandNames !== []) {
                $brand->orWhereIn('name', $brandNames);
            }
        });
    }

    public static function applyTextFilter(Builder $query, string $column, string $term): void
    {
        $term = trim($term);
        if ($term === '') {
            return;
        }

        $patterns = self::likePatterns($term);
        if ($patterns === []) {
            return;
        }

        $query->where(function (Builder $inner) use ($column, $patterns): void {
            foreach ($patterns as $pattern) {
                $inner->orWhereRaw('LOWER('.$column.') LIKE ?', [mb_strtolower($pattern)]);
            }
        });
    }

    /** @return list<string> */
    public static function likePatterns(string $term): array
    {
        $term = trim($term);
        if ($term === '') {
            return [];
        }

        $patterns = [];
        foreach (self::termVariants($term) as $variant) {
            $patterns[] = '%'.$variant.'%';
        }

        return array_values(array_unique($patterns));
    }

    /** @return list<string> */
    private static function termVariants(string $term): array
    {
        $variants = [$term, self::normalize($term)];

        if (preg_match('/^[a-zA-Z0-9\s\-]+$/', $term)) {
            $variants[] = strtolower($term);
            $variants[] = strtoupper($term);
            $variants[] = ucwords(strtolower($term));
        }

        $base = self::normalize($term);
        foreach (['ا', 'أ', 'إ', 'آ'] as $alef) {
            $variants[] = str_replace('ا', $alef, $base);
        }

        $variants[] = str_replace(' ', '', $base);

        foreach (self::matchingSynonymGroups($term) as $group) {
            foreach ($group as $member) {
                $variants[] = $member;
                $variants[] = self::normalize($member);
                if (preg_match('/^[a-zA-Z0-9\s\-]+$/', $member)) {
                    $variants[] = strtolower($member);
                    $variants[] = ucwords(strtolower($member));
                }
            }
        }

        return array_values(array_unique(array_filter($variants, fn (string $value): bool => $value !== '')));
    }

    /** @return list<list<string>> */
    private static function matchingSynonymGroups(string $term): array
    {
        $matches = [];

        foreach (self::SYNONYM_GROUPS as $group) {
            foreach ($group as $member) {
                if (self::containsTerm($member, $term)) {
                    $matches[] = $group;
                    break;
                }
            }
        }

        return $matches;
    }

    public static function normalize(string $text): string
    {
        $text = trim($text);
        $text = preg_replace('/[\x{064B}-\x{065F}\x{0670}]/u', '', $text) ?? $text;
        $text = str_replace(
            ['أ', 'إ', 'آ', 'ٱ', 'ؤ', 'ئ', 'ى', 'ة'],
            ['ا', 'ا', 'ا', 'ا', 'و', 'ي', 'ي', 'ه'],
            $text
        );

        return preg_replace('/\s+/u', ' ', $text) ?? $text;
    }

    /** @return list<string> */
    private static function matchingBrandNames(string $term): array
    {
        $normalizedTerm = self::normalize($term);
        $matches = [];

        foreach (self::BRAND_ALIASES as $brand => $aliases) {
            if (self::containsTerm($brand, $term)) {
                $matches[] = $brand;

                continue;
            }

            foreach ($aliases as $alias) {
                if (self::containsTerm($alias, $term) || self::containsTerm($term, $alias)) {
                    $matches[] = $brand;
                    break;
                }
            }

            if (self::containsTerm($normalizedTerm, self::normalize($brand))) {
                $matches[] = $brand;
            }
        }

        return array_values(array_unique($matches));
    }

    private static function containsTerm(string $haystack, string $needle): bool
    {
        if ($needle === '') {
            return false;
        }

        $haystackNorm = self::normalize($haystack);
        $needleNorm = self::normalize($needle);

        return str_contains($haystack, $needle)
            || str_contains($haystackNorm, $needleNorm)
            || str_contains($needleNorm, $haystackNorm)
            || (preg_match('/^[a-zA-Z0-9\s\-]+$/', $needle) && str_contains(strtolower($haystack), strtolower($needle)));
    }

    /** @param list<string> $columns */
    /** @param list<string> $patterns */
    private static function orWhereColumnsLike(Builder $query, array $columns, array $patterns): void
    {
        foreach ($columns as $column) {
            foreach ($patterns as $pattern) {
                $query->orWhereRaw('LOWER('.$column.') LIKE ?', [mb_strtolower($pattern)]);
            }
        }
    }
}
