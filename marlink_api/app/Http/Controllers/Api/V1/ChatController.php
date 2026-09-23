<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\MessageSent;
use App\Http\Resources\V1\MessageResource;
use App\Models\Message;
use App\Models\MessageAttachment;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ChatController extends ApiBaseController
{
    /**
     * Get paginated messages for a room.
     */
    public function index(Request $request, int $roomId): JsonResponse
    {
        $perPage = (int) $request->input('per_page', 30);

        $messages = Message::where('room_id', $roomId)
            ->with(['user.profile', 'attachments', 'replyTo.user'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return $this->successResponse([
            'messages' => MessageResource::collection($messages),
            'pagination' => [
                'current_page' => $messages->currentPage(),
                'has_more' => $messages->hasMorePages(),
                'total' => $messages->total(),
            ],
        ], 'Messages retrieved.');
    }

    /**
     * Send a text or shared-location message into a room.
     */
    public function store(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'message_type' => ['required', 'in:text,location'],
            'content' => ['required_if:message_type,text', 'nullable', 'string', 'max:5000'],
            'reply_to_id' => ['nullable', 'exists:messages,id'],
            'latitude' => ['required_if:message_type,location', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['required_if:message_type,location', 'nullable', 'numeric', 'between:-180,180'],
            'location_label' => ['nullable', 'string', 'max:150'],
        ]);

        $message = Message::create([
            'room_id' => $roomId,
            'user_id' => $user->id,
            'reply_to_id' => $validated['reply_to_id'] ?? null,
            'message_type' => $validated['message_type'],
            'content' => $validated['content'] ?? null,
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'location_label' => $validated['location_label'] ?? null,
            'is_deleted' => false,
        ]);

        $message->load(['user.profile', 'attachments', 'replyTo.user']);

        // Broadcast to room members via WebSocket
        broadcast(new MessageSent($message))->toOthers();

        return $this->successResponse(new MessageResource($message), 'Message sent.', 201);
    }

    /**
     * Upload an image attachment and dispatch an image message.
     */
    public function uploadMedia(Request $request, int $roomId): JsonResponse
    {
        $user = $request->user();

        $request->validate([
            'image' => ['required', 'file', 'image', 'mimes:jpeg,png,jpg,webp', 'max:10240'], // 10MB limit
            'caption' => ['nullable', 'string', 'max:1000'],
            'reply_to_id' => ['nullable', 'exists:messages,id'],
        ]);

        $file = $request->file('image');
        $fileName = $file->getClientOriginalName();
        $fileSize = $file->getSize();
        $mimeType = $file->getMimeType();

        $storedPath = $file->store("chat_media/{$roomId}", 'public');
        $fileUrl = Storage::disk('public')->url($storedPath);

        $message = DB::transaction(function () use ($roomId, $user, $request, $storedPath, $fileUrl, $fileName, $fileSize, $mimeType) {
            $msg = Message::create([
                'room_id' => $roomId,
                'user_id' => $user->id,
                'reply_to_id' => $request->input('reply_to_id'),
                'message_type' => 'image',
                'content' => $request->input('caption'),
                'is_deleted' => false,
            ]);

            MessageAttachment::create([
                'message_id' => $msg->id,
                'file_path' => $storedPath,
                'file_url' => $fileUrl,
                'file_name' => $fileName,
                'file_size' => $fileSize,
                'mime_type' => $mimeType,
            ]);

            return $msg;
        });

        $message->load(['user.profile', 'attachments', 'replyTo.user']);

        broadcast(new MessageSent($message))->toOthers();

        return $this->successResponse(new MessageResource($message), 'Image uploaded and sent.', 201);
    }

    /**
     * Soft delete a message sent by the user.
     */
    public function destroy(Request $request, int $roomId, int $messageId): JsonResponse
    {
        $message = Message::where('room_id', $roomId)->where('id', $messageId)->firstOrFail();

        if ($message->user_id !== $request->user()->id) {
            return $this->errorResponse('You can only delete your own messages.', null, 403);
        }

        $message->update(['is_deleted' => true]);

        return $this->successResponse(null, 'Message deleted.');
    }
}
