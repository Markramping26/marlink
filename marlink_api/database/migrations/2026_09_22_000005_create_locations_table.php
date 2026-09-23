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
        Schema::create('locations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->onDelete('cascade');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->float('accuracy')->nullable(); // in meters
            $table->float('altitude')->nullable(); // in meters
            $table->float('speed')->nullable(); // in km/h
            $table->float('heading')->nullable(); // 0 - 360 degrees
            $table->unsignedTinyInteger('battery_pct')->nullable();
            $table->boolean('is_moving')->default(false);
            $table->timestamp('recorded_at');
            $table->timestamps();

            $table->index(['latitude', 'longitude']);
            $table->index('recorded_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('locations');
    }
};
