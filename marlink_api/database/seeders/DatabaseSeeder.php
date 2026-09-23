<?php

namespace Database\Seeders;

use App\Models\Location;
use App\Models\Message;
use App\Models\Place;
use App\Models\Room;
use App\Models\RoomMember;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Create Mark (Account Creator)
        $mark = User::create([
            'name' => 'Mark Lawrence',
            'username' => 'mark',
            'email' => 'mark@marlink.local',
            'phone' => '+639171234567',
            'password' => Hash::make('Password123!'),
            'is_active' => true,
        ]);

        UserProfile::create([
            'user_id' => $mark->id,
            'bio' => 'Always on the move.',
            'battery_pct' => 88,
            'sharing_status' => 'on',
            'show_speed' => true,
            'show_battery' => true,
            'allow_geofence_alerts' => true,
            'last_seen_at' => now(),
        ]);

        Location::create([
            'user_id' => $mark->id,
            'latitude' => 14.5547,
            'longitude' => 121.0244, // Makati
            'accuracy' => 5.2,
            'speed' => 45.0,
            'heading' => 45.0,
            'battery_pct' => 88,
            'is_moving' => true,
            'recorded_at' => now(),
        ]);

        // 2. Create Anna
        $anna = User::create([
            'name' => 'Anna Lawrence',
            'username' => 'anna',
            'email' => 'anna@marlink.local',
            'phone' => '+639179876543',
            'password' => Hash::make('Password123!'),
            'is_active' => true,
        ]);

        UserProfile::create([
            'user_id' => $anna->id,
            'bio' => 'Graphic designer & traveler',
            'battery_pct' => 92,
            'sharing_status' => 'on',
            'show_speed' => true,
            'show_battery' => true,
            'allow_geofence_alerts' => true,
            'last_seen_at' => now(),
        ]);

        Location::create([
            'user_id' => $anna->id,
            'latitude' => 14.5580,
            'longitude' => 121.0195,
            'accuracy' => 6.0,
            'speed' => 0.0,
            'heading' => 0.0,
            'battery_pct' => 92,
            'is_moving' => false,
            'recorded_at' => now(),
        ]);

        // 3. Create John
        $john = User::create([
            'name' => 'John Santos',
            'username' => 'john',
            'email' => 'john@marlink.local',
            'phone' => '+639185551234',
            'password' => Hash::make('Password123!'),
            'is_active' => true,
        ]);

        UserProfile::create([
            'user_id' => $john->id,
            'bio' => 'Work & Coffee',
            'battery_pct' => 68,
            'sharing_status' => 'on',
            'show_speed' => true,
            'show_battery' => true,
            'allow_geofence_alerts' => true,
            'last_seen_at' => now(),
        ]);

        Location::create([
            'user_id' => $john->id,
            'latitude' => 14.5505,
            'longitude' => 121.0310,
            'accuracy' => 8.1,
            'speed' => 47.0,
            'heading' => 60.0,
            'battery_pct' => 68,
            'is_moving' => true,
            'recorded_at' => now()->subSeconds(2),
        ]);

        // 4. Create "Family" Room
        $familyRoom = Room::create([
            'code' => 'FAM-82K4',
            'name' => 'Family',
            'description' => 'Official family safety & location sharing group.',
            'created_by' => $mark->id,
            'is_active' => true,
        ]);

        RoomMember::create([
            'room_id' => $familyRoom->id,
            'user_id' => $mark->id,
            'role' => 'owner',
            'is_location_enabled' => true,
            'joined_at' => now()->subDays(10),
        ]);

        RoomMember::create([
            'room_id' => $familyRoom->id,
            'user_id' => $anna->id,
            'role' => 'admin',
            'is_location_enabled' => true,
            'joined_at' => now()->subDays(9),
        ]);

        RoomMember::create([
            'room_id' => $familyRoom->id,
            'user_id' => $john->id,
            'role' => 'member',
            'is_location_enabled' => true,
            'joined_at' => now()->subDays(5),
        ]);

        // 5. Seed Place
        Place::create([
            'room_id' => $familyRoom->id,
            'created_by' => $mark->id,
            'name' => 'Home',
            'icon' => 'home',
            'latitude' => 14.5545,
            'longitude' => 121.0240,
            'radius_meters' => 200,
            'is_active' => true,
        ]);

        // 6. Seed Sample Message
        Message::create([
            'room_id' => $familyRoom->id,
            'user_id' => $mark->id,
            'message_type' => 'text',
            'content' => 'Welcome to MarLink Family room! Remember to keep your location sharing enabled.',
            'is_deleted' => false,
        ]);
    }
}
