/**
 * OBS WebSocket controller — connects to OBS Studio to start/stop
 * screen recording for gameplay capture.
 *
 * Requires OBS Studio v28+ with WebSocket server enabled (built-in).
 * Default: ws://localhost:4455 (no password by default).
 */

import OBSWebSocket from "obs-websocket-js";

export interface OBSConfig {
  host: string;
  port: number;
  password?: string;
}

const DEFAULT_CONFIG: OBSConfig = {
  host: "localhost",
  port: 4455,
};

export class OBSController {
  private obs: OBSWebSocket;
  private config: OBSConfig;
  private connected = false;

  constructor(config: Partial<OBSConfig> = {}) {
    this.obs = new OBSWebSocket();
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Connect to OBS WebSocket server.
   */
  async connect(): Promise<void> {
    if (this.connected) return;

    const url = `ws://${this.config.host}:${this.config.port}`;
    console.log(`Connecting to OBS at ${url}...`);

    try {
      await this.obs.connect(url, this.config.password);
      this.connected = true;
      console.log("Connected to OBS");
    } catch (err) {
      throw new Error(
        `Failed to connect to OBS at ${url}. ` +
          `Ensure OBS is running with WebSocket server enabled (Tools > WebSocket Server Settings). ` +
          `Error: ${err instanceof Error ? err.message : String(err)}`
      );
    }
  }

  /**
   * Disconnect from OBS.
   */
  async disconnect(): Promise<void> {
    if (!this.connected) return;
    this.obs.disconnect();
    this.connected = false;
    console.log("Disconnected from OBS");
  }

  /**
   * Start recording.
   */
  async startRecording(): Promise<void> {
    this.ensureConnected();
    const status = await this.obs.call("GetRecordStatus");
    if (status.outputActive) {
      console.log("OBS is already recording");
      return;
    }
    await this.obs.call("StartRecord");
    console.log("OBS recording started");
  }

  /**
   * Stop recording and return the output file path.
   */
  async stopRecording(): Promise<string> {
    this.ensureConnected();
    const result = await this.obs.call("StopRecord");
    console.log(`OBS recording stopped: ${result.outputPath}`);
    return result.outputPath;
  }

  /**
   * Get current recording status.
   */
  async getRecordingStatus(): Promise<{
    active: boolean;
    paused: boolean;
    duration: string;
    bytes: number;
  }> {
    this.ensureConnected();
    const status = await this.obs.call("GetRecordStatus");
    return {
      active: status.outputActive,
      paused: status.outputPaused,
      duration: status.outputTimecode,
      bytes: status.outputBytes,
    };
  }

  /**
   * Set the recording output path (directory).
   */
  async setOutputPath(dir: string): Promise<void> {
    this.ensureConnected();
    await this.obs.call("SetProfileParameter", {
      parameterCategory: "Output",
      parameterName: "FilenameFormatting",
      parameterValue: "%CCYY-%MM-%DD_%hh-%mm-%ss",
    });
    await this.obs.call("SetRecordDirectory", {
      recordDirectory: dir,
    });
    console.log(`OBS output directory set to: ${dir}`);
  }

  /**
   * Get the list of scenes.
   */
  async getScenes(): Promise<string[]> {
    this.ensureConnected();
    const { scenes } = await this.obs.call("GetSceneList");
    return scenes.map((s) => s.sceneName as string);
  }

  /**
   * Switch to a specific scene (useful for selecting the Roblox capture scene).
   */
  async setScene(sceneName: string): Promise<void> {
    this.ensureConnected();
    await this.obs.call("SetCurrentProgramScene", {
      sceneName,
    });
    console.log(`OBS scene switched to: ${sceneName}`);
  }

  private ensureConnected(): void {
    if (!this.connected) {
      throw new Error("Not connected to OBS. Call connect() first.");
    }
  }
}
