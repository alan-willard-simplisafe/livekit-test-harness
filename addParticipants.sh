#!/bin/bash
set -e

# Configuration
LIVEKIT_URL="ws://localhost:7880"
LIVEKIT_KEY="TEST_API_KEY"
LIVEKIT_SECRET="nHOGGjApuwaGLSRjuRVNewPLhTRkOyoz"
NUM_PARTICIPANTS=10
ROOM_PREFIX="test-room"
PARTICIPANT_PREFIX="participant"
LATENCY=4

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--num-participants)
            NUM_PARTICIPANTS="$2"
            shift 2
            ;;
        -l|--latency)
            LATENCY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -n, --num-participants NUM   Number of participants (default: 10)"
            echo "  -l, --latency LATENCY        Network latency in ms (default: 4)"
            echo "  -h, --help                   Show this help"
            exit 0
            ;;
        *)
            # If it's just a number without flag, treat it as NUM_PARTICIPANTS
            if [[ $1 =~ ^[0-9]+$ ]]; then
                NUM_PARTICIPANTS="$1"
                shift
            else
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
            fi
            ;;
    esac
done


echo "Creating $NUM_PARTICIPANTS participants in separate rooms..."

# Function to create a participant in a room
create_participant() {
    local room_num=$1
    local room_name="${ROOM_PREFIX}-${room_num}"
    local participant_name="${PARTICIPANT_PREFIX}-${room_num}"
    
    echo "Creating participant $participant_name in room $room_name..."
    
    # Create room first (if it doesn't exist)
    # lk room create \
    #     --url "$LIVEKIT_URL" \
    #     --api-key "$LIVEKIT_KEY" \
    #     --api-secret "$LIVEKIT_SECRET" \
    #     --name "$room_name" \
    #     2>/dev/null || echo "Room $room_name may already exist"
    
    # Join participant to room
    lk room join \
        --url "$LIVEKIT_URL" \
        --api-key "$LIVEKIT_KEY" \
        --api-secret "$LIVEKIT_SECRET" \
        --room "$room_name" \
        --identity "$participant_name" \
        --auto-subscribe=true \
        &
    
    # Small delay to avoid overwhelming the server
    # sleep 0.1
}

echo "Updating toxiproxy latency to ${LATENCY}ms..."

# Get list of existing toxics for the redis proxy
echo "Checking existing toxics..."
curl -s http://localhost:8474/proxies/redis/toxics

# Remove existing latency toxic (if any)
echo "Removing existing latency toxic..."
curl -X DELETE http://localhost:8474/proxies/redis/toxics/latency_downstream 2>/dev/null || echo "No existing downstream latency toxic"
curl -X DELETE http://localhost:8474/proxies/redis/toxics/latency_upstream 2>/dev/null || echo "No existing upstream latency toxic"

# Add new latency toxic
echo "Adding new latency toxic (${LATENCY}ms)..."
curl -X POST http://localhost:8474/proxies/redis/toxics \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"latency\",\"attributes\":{\"latency\":${LATENCY}}}"

echo "Toxiproxy latency updated to ${LATENCY}ms"


# Create participants in parallel
for i in $(seq 1 $NUM_PARTICIPANTS); do
    create_participant $i
    
    # Every 10 participants, wait a bit longer
    if [ $((i % 10)) -eq 0 ]; then
        echo "Created $i participants, pausing briefly..."
        # sleep 2
    fi
done

echo "All $NUM_PARTICIPANTS participants created!"
echo "Participants will remain connected in the background."
echo "To disconnect all participants, run: pkill -f 'lk room join'"

# Optional: Wait for user input before disconnecting
read -p "Press Enter to disconnect all participants..."
pkill -f 'lk room join' || echo "No participants to disconnect"
echo "All participants disconnected."
