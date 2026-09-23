<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\V1\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;

class ProfileController extends ApiBaseController
{
    /**
     * Update user profile, avatar, or location sharing settings.
     */
    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $profile = $user->profile ?? $user->profile()->create(['battery_pct' => 100]);
        $validated = $request->validated();

        // 1. Update User basic info
        $userUpdate = [];
        if (isset($validated['name'])) $userUpdate['name'] = $validated['name'];
        if (isset($validated['username'])) $userUpdate['username'] = $validated['username'];
        if (isset($validated['phone'])) $userUpdate['phone'] = $validated['phone'];
        if (!empty($userUpdate)) {
            $user->update($userUpdate);
        }

        // 2. Handle Avatar file upload
        if ($request->hasFile('avatar')) {
            if ($profile->avatar_url) {
                // Delete old avatar if local
                $oldPath = str_replace(Storage::disk('public')->url(''), '', $profile->avatar_url);
                Storage::disk('public')->delete($oldPath);
            }

            $path = $request->file('avatar')->store('avatars', 'public');
            $profile->avatar_url = Storage::disk('public')->url($path);
        }

        // 3. Update Profile attributes & Location Sharing controls
        if (isset($validated['bio'])) $profile->bio = $validated['bio'];
        if (isset($validated['battery_pct'])) $profile->battery_pct = $validated['battery_pct'];
        if (isset($validated['show_speed'])) $profile->show_speed = $validated['show_speed'];
        if (isset($validated['show_battery'])) $profile->show_battery = $validated['show_battery'];
        if (isset($validated['allow_geofence_alerts'])) $profile->allow_geofence_alerts = $validated['allow_geofence_alerts'];

        if (isset($validated['sharing_status'])) {
            $profile->sharing_status = $validated['sharing_status'];

            if ($validated['sharing_status'] === 'on' && !empty($validated['sharing_duration_minutes'])) {
                $profile->sharing_expires_at = now()->addMinutes($validated['sharing_duration_minutes']);
            } elseif ($validated['sharing_status'] === 'off' || $validated['sharing_status'] === 'paused') {
                $profile->sharing_expires_at = null;
            }
        }

        $profile->last_seen_at = now();
        $profile->save();

        $user->load('profile');

        return $this->successResponse(new UserResource($user), 'Profile updated successfully.');
    }
}
