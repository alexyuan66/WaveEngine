import std.string;
import std.conv;
import std.stdio;
import std.exception;

import bindbc.sdl;
import sdl_abstraction;

/**
 * A loaded sound artifact.
 *
 * Not intended to be called outside of AudioManager.
 * @see AudioManager
 */
class AudioResource {
    /**
     * Load a `.wav` file into memory.
     *
     * @param audioFilePath the path to the `.wav` file.
     * @param volume the volume scale to apply to the loaded waveform.
     */
    this(string audioFilePath, int volume = MIX_MAX_VOLUME) {
        mSound = Mix_LoadWAV(audioFilePath.toStringz);
        if (mSound is null) {
            writeln("Error loading sound: ", Mix_GetError());
        }
        Mix_VolumeChunk(mSound, volume);
    }

    /**
     * Destroy loaded `.wav` file.
     */
    ~this() {
        if (mSound !is null) {
            Mix_FreeChunk(mSound);
        }
    }

    /**
     * The loaded sound chunk.
     */
    Mix_Chunk* mSound;
}

/**
 * Interfaces with `SDL_Mixer` to start/stop a sound.
 *
 * Not intended to be called outside of AudioManager.
 * @see AudioManager
 */
struct AudioRequest {
    /**
     * Create a request for `SDL_Mixer` to play audio.
     *
     * @param audio the AudioResource corresponding to the request
     * @param volume how loud to play the sound
     * @param loops the number of times to play the sound before terminating
     */
    this(AudioResource audio, int volume, int loops) {
        mAudio = audio;
        mVolume = volume;
        mLoops = loops;
    }

    /**
     * Start playing the sound.
     *
     * The sound parameters are pulled from #mAudio, #mVolume, and #mLoops.
     */
    int Play() {
        Mix_VolumeChunk(mAudio.mSound, mVolume);
        mChannel = Mix_PlayChannel(-1, mAudio.mSound, mLoops);
        if (mChannel == -1) {
            writeln("Error playing sound: ", Mix_GetError());
        }
        return mChannel;
    }

    /**
     * Stop playing the sound.
     */
    void Stop() {
        if (mChannel != -1) {
            Mix_HaltChannel(mChannel);
        }
    }

    AudioResource mAudio;       /**< The AudioResource containing the audio data to play. */
    int mVolume;                /**< The volume at which to play the audio. */
    int mLoops;                 /**< The number of times to play the sound before terminating. */
    private int mChannel = -1;
}

/**
 * Manages playing/combining audio effects and background music.
 *
 * Instances of this class store loaded AudioResource and AudioRequest objects.
 * @see AudioResource
 * @see AudioRequest
 */
class AudioManager {
    /**
     * Initialize `SDL_Mixer`.
     */
    this() {
        if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) == -1) {
            writeln("Error initializing SDL_mixer: ", Mix_GetError());
        }
    }

    /**
     * Cleanup `SDL_Mixer` audio.
     */
    ~this() {
        Mix_CloseAudio();
    }

    /** 
     * Load an AudioResource from a given file name.
     *
     * @param audioName the name to use to reference this sound in the future.
     * @param audioPath the path to a `.wav` file containing the audio.
     */
    void AddAudioResource(string audioName, string audioPath) {
        mAudioResourceMap[audioName] = new AudioResource(audioPath);
    }

    /**
     * Play a given sound indefinitely.
     *
     * @param audio the name of the audio source to play.
     * @param volume an `int` controlling the volume at which to play.
     */
    void PlayIndefinitely(string audio, int volume = 10) {
        mBackgroundMusic = AudioRequest(mAudioResourceMap[audio], volume, -1);
        mBackgroundMusicActive = true;
        mBackgroundMusic.Play();
    }

    /**
     * Stop playing all sounds that are playing indefinitely.
     */
    void StopBackgroundMusic() {
        if (mBackgroundMusicActive) {
            mBackgroundMusic.Stop();
            mBackgroundMusicActive = false;
        }
    }

    /**
     * Play a given sound a certain number of times.
     *
     * @param audio the name of the audio source to play.
     * @param volume an `int` controlling the volume at which to play.
     * @param loops the number of times to play the effect (default: `0`).
     */
    void PlayEffect(string audio, int volume = 20, int loops = 0) {
        auto effectReq = AudioRequest(mAudioResourceMap[audio], volume, loops);
        mEffects ~= effectReq;
        effectReq.Play();
    }

    /**
     * Stop playing all one-time sounds that are playing.
     */
    void StopAllEffects() {
        foreach (effect; mEffects) {
            effect.Stop();
        }
        mEffects.length = 0;
    }

    AudioResource[string] mAudioResourceMap;    /**< Stored AudioResource instances. */
    AudioRequest mBackgroundMusic;              /**< The currently playing background music's AudioRequest. */
    bool mBackgroundMusicActive = false;        /**< Whether any background music is currently being playes. */
    AudioRequest[] mEffects;                    /**< The currently playing sound effects that will not loop forever. */
}
