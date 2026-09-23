<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\V1\PlaceResource;
use App\Models\GeofenceEvent;
use App\Models\Place;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlaceController extends ApiBaseController
{
    /**
     * List all geofenced places in a room.
     */
    public function index(Request $request, int $roomId): JsonResponse
    {
        $places = Place::where('room_id', $roomId)->where('is_active', true)->get();

        return $this->successResponse(PlaceResource::collection($places), 'Places retrieved.');
    }

    /**
     * Create a new geofenced place in a room.
     */
    public function store(Request $request, int $roomId): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'icon' => ['nullable', 'string', 'max:50'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'radius_meters' => ['nullable', 'integer', 'min:50', 'max:5000'],
        ]);

        $place = Place::create([
            'room_id' => $roomId,
            'created_by' => $request->user()->id,
            'name' => $validated['name'],
            'icon' => $validated['icon'] ?? 'location_pin',
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'radius_meters' => $validated['radius_meters'] ?? 150,
            'is_active' => true,
        ]);

        return $this->successResponse(new PlaceResource($place), 'Place created successfully.', 201);
    }

    /**
     * Update a geofenced place.
     */
    public function update(Request $request, int $roomId, int $placeId): JsonResponse
    {
        $place = Place::where('room_id', $roomId)->where('id', $placeId)->firstOrFail();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'icon' => ['nullable', 'string', 'max:50'],
            'latitude' => ['sometimes', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'numeric', 'between:-180,180'],
            'radius_meters' => ['sometimes', 'integer', 'min:50', 'max:5000'],
        ]);

        $place->update($validated);

        return $this->successResponse(new PlaceResource($place), 'Place updated.');
    }

    /**
     * Delete a place.
     */
    public function destroy(Request $request, int $roomId, int $placeId): JsonResponse
    {
        $place = Place::where('room_id', $roomId)->where('id', $placeId)->firstOrFail();
        $place->delete();

        return $this->successResponse(null, 'Place deleted.');
    }

    /**
     * Evaluate geofence boundaries for user's current coordinate.
     * Uses Haversine formula locally without external APIs.
     */
    public function checkGeofence(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
        ]);

        $lat = $validated['latitude'];
        $lng = $validated['longitude'];

        $places = Place::where('room_id', $roomId)->where('is_active', true)->get();
        $events = [];

        foreach ($places as $place) {
            $distance = $this->calculateHaversineDistance($lat, $lng, $place->latitude, $place->longitude);
            $isInside = $distance <= $place->radius_meters;

            // Check previous state
            $lastEvent = GeofenceEvent::where('place_id', $place->id)
                ->where('user_id', $user->id)
                ->latest('triggered_at')
                ->first();

            $lastWasInside = $lastEvent ? ($lastEvent->event_type === 'enter') : false;

            if ($isInside && !$lastWasInside) {
                // User entered place
                $event = GeofenceEvent::create([
                    'place_id' => $place->id,
                    'user_id' => $user->id,
                    'event_type' => 'enter',
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'triggered_at' => now(),
                ]);
                $events[] = [
                    'event' => 'enter',
                    'place_name' => $place->name,
                    'user_name' => $user->name,
                ];
            } elseif (!$isInside && $lastWasInside) {
                // User left place
                $event = GeofenceEvent::create([
                    'place_id' => $place->id,
                    'user_id' => $user->id,
                    'event_type' => 'leave',
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'triggered_at' => now(),
                ]);
                $events[] = [
                    'event' => 'leave',
                    'place_name' => $place->name,
                    'user_name' => $user->name,
                ];
            }
        }

        return $this->successResponse($events, 'Geofence evaluation complete.');
    }

    /**
     * Local Haversine geographic distance in meters.
     */
    private function calculateHaversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000; // in meters

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
