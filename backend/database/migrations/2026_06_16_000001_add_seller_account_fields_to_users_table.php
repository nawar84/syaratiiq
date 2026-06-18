<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('username')->nullable()->unique()->after('phone');
            $table->string('showroom_name')->nullable()->after('username');
            $table->foreignId('province_id')->nullable()->after('showroom_name')->constrained()->nullOnDelete();
            $table->string('subscription_type')->nullable()->after('province_id');
            $table->timestamp('subscription_start')->nullable()->after('subscription_type');
            $table->timestamp('subscription_end')->nullable()->after('subscription_start');
            $table->string('account_status')->nullable()->default('active')->after('subscription_end');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('province_id');
            $table->dropColumn([
                'username',
                'showroom_name',
                'subscription_type',
                'subscription_start',
                'subscription_end',
                'account_status',
            ]);
        });
    }
};
