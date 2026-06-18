<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MarketplaceSearchTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        $this->seed(\Database\Seeders\VirtualShowroomsSeeder::class);
    }

    public function test_car_search_arabic_terms_return_results(): void
    {
        foreach (['أبيض', 'بنزين', 'تويوتا', 'Camry', 'أوتوماتيك'] as $term) {
            $response = $this->getJson('/api/cars?search='.urlencode($term));
            $response->assertOk();
            $this->assertGreaterThan(
                0,
                $response->json('total'),
                "Arabic/Latin car search failed for term: {$term}"
            );
        }
    }

    public function test_car_search_english_terms_return_results(): void
    {
        foreach (['white', 'petrol', 'Toyota', 'Camry', 'automatic'] as $term) {
            $response = $this->getJson('/api/cars?search='.urlencode($term));
            $response->assertOk();
            $this->assertGreaterThan(
                0,
                $response->json('total'),
                "English car search failed for term: {$term}"
            );
        }
    }

    public function test_car_search_arabic_and_english_color_synonyms_match(): void
    {
        $arabic = $this->getJson('/api/cars?search='.urlencode('أبيض'))->json('total');
        $english = $this->getJson('/api/cars?search=white')->json('total');

        $this->assertSame($arabic, $english, 'Arabic/English color synonym counts should match');
        $this->assertGreaterThan(0, $arabic);
    }

    public function test_car_search_arabic_and_english_fuel_synonyms_match(): void
    {
        $arabic = $this->getJson('/api/cars?search='.urlencode('بنزين'))->json('total');
        $english = $this->getJson('/api/cars?search=petrol')->json('total');

        $this->assertSame($arabic, $english, 'Arabic/English fuel synonym counts should match');
        $this->assertGreaterThan(0, $arabic);
    }

    public function test_car_search_brand_filter_arabic_and_english(): void
    {
        $arabic = $this->getJson('/api/cars?brand='.urlencode('تويوتا'))->json('total');
        $english = $this->getJson('/api/cars?brand=Toyota')->json('total');

        $this->assertGreaterThan(0, $arabic);
        $this->assertSame($arabic, $english);
    }

    public function test_showroom_search_arabic_and_english(): void
    {
        $arabic = $this->getJson('/api/showrooms?search='.urlencode('بغداد'));
        $arabic->assertOk();
        $this->assertGreaterThan(0, $arabic->json('total'));

        $english = $this->getJson('/api/showrooms?search=Baghdad');
        $english->assertOk();
        $this->assertSame($arabic->json('total'), $english->json('total'));
    }

    public function test_showroom_search_by_name_arabic(): void
    {
        $response = $this->getJson('/api/showrooms?search='.urlencode('معرض البركة'));
        $response->assertOk();
        $this->assertGreaterThan(0, $response->json('total'));
    }

    public function test_car_search_nonsense_returns_empty(): void
    {
        $response = $this->getJson('/api/cars?search='.urlencode('zzzznotfound999'));
        $response->assertOk();
        $this->assertSame(0, $response->json('total'));
    }

    public function test_car_color_filter_arabic_and_english(): void
    {
        $arabic = $this->getJson('/api/cars?color='.urlencode('أبيض'))->json('total');
        $english = $this->getJson('/api/cars?color=white')->json('total');

        $this->assertGreaterThan(0, $arabic);
        $this->assertSame($arabic, $english);
    }

    public function test_car_search_kia_arabic_and_english(): void
    {
        $arabic = $this->getJson('/api/cars?search='.urlencode('كيا'))->json('total');
        $english = $this->getJson('/api/cars?search=KIA')->json('total');

        $this->assertGreaterThan(0, $arabic);
        $this->assertSame($arabic, $english);
    }

    public function test_car_search_works_with_single_optional_field(): void
    {
        $brandOnly = $this->getJson('/api/cars?brand='.urlencode('كيا'));
        $brandOnly->assertOk();
        $this->assertGreaterThan(0, $brandOnly->json('total'));

        $colorOnly = $this->getJson('/api/cars?color='.urlencode('أبيض'));
        $colorOnly->assertOk();
        $this->assertGreaterThan(0, $colorOnly->json('total'));

        $modelOnly = $this->getJson('/api/cars?model=Camry');
        $modelOnly->assertOk();
        $this->assertGreaterThan(0, $modelOnly->json('total'));
    }
}
