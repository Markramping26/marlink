<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('user_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('avatar_url')->nullable();
            $table->string('bio', 255)->nullable();
            $table->unsignedTinyInteger('battery_pct')->default(100);
            $table->enum('sharing_status', ['on', 'paused', 'off'])->default('on');
            $table->timestamp('sharing_expires_at')->nullable();
            $table->boolean('show_speed')->default(true);
            $table->boolean('show_battery')->default(true);
            $table->boolean('allow_geofence_alerts')->default(true);
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();

            $table->index('sharing_status');
            $table->index('last_seen_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_profiles');
    }
};
