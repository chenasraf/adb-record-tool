# record-adb

A simple, scriptable workflow for recording, pulling, and compressing Android screen recordings
using ADB.

## Features

- ✅ Record Android screen using `adb shell screenrecord`
- ✅ Manual stop via Ctrl+C without corrupting the output
- ✅ Automatically remembers your recording parameters
- ✅ Finalize: Pull and delete the recording from the device
- ✅ Compress recorded videos using `ffmpeg`

## Usage

### 1. Start Recording

```bash
./record-adb.sh record [--size <num>] [--output <name>]
```

- `--size`: Target resolution (e.g. `300` becomes `300x300`)
- `--output`: Base filename (default: `screencast`)

> 📌 Press `Ctrl+C` when you're done recording
>
> 📌 If resolution is omitted, it will be the detected screen size from the device

### 2. Finalize Recording

```bash
./record-adb.sh finalize
```

- Pulls the video from your device
- Deletes the remote file
- Uses the parameters saved from the `record` step

### 3. Compress Recording

```bash
./record-adb.sh compress [--output <name>]
```

- Compresses `<name>.mp4` into `<name>_compressed.mp4`
- If no name is provided, it uses the last recorded filename

## Examples

```bash
# Record a 480x480 video named "demo"
./record-adb.sh record --size 480 --output demo

# After Ctrl+C, finalize it
./record-adb.sh finalize

# Compress it
./record-adb.sh compress
```

## Requirements

- `adb` (Android Debug Bridge)
- `ffmpeg` (for compression)

## License

MIT

## Contributing

I am developing this package on my free time, so any support, whether code, issues, or just stars is
very helpful to sustaining its life. If you are feeling incredibly generous and would like to donate
just a small amount to help sustain this project, I would be very very thankful!

<a href='https://ko-fi.com/casraf' target='_blank'>
  <img height='36' style='border:0px;height:36px;'
    src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
    alt='Buy Me a Coffee at ko-fi.com' />
</a>

I welcome any issues or pull requests on GitHub. If you find a bug, or would like a new feature,
don't hesitate to open an appropriate issue and I will do my best to reply promptly.
