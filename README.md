# livekit-test-harness

Steps to reproduce issue as seen in https://github.com/livekit/livekit/issues/3858
1. Start containers with `docker compose up`
2. Run the `addRooms` script



Examples
-  `./addRooms.sh -n 40 -l 100` Sets up a 100ms latency between Livekit and Redis, and attempts to start 40 rooms. 
Result Output:
    ```
    Found 28 rooms (expected 40)
    ERROR: Number of rooms (28) does not match expected (40
    ```
-  `./addRooms.sh -n 40 -l 5` Sets up a 5ms latency between Livekit and Redis, and attempts to start 40 rooms. 
Result Output:
    ```
    Found 40 rooms (expected 40)
    ```