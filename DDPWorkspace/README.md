# DDPWorkspace

A convenient wrapper tool for working with DDP Mastering Tools to convert CUE/WAV files into DDP (Disc Description Protocol) format.

## Prerequisites

- Windows operating system
- [DDP Mastering Tools](http://ddp.andreasruge.de/)

## Setup

1. **Download DDP Mastering Tools**
   - Download the DDP Mastering Tools package from the link above

2. **Extract to Root Directory**
   - Extract the downloaded tools to your desired root directory

3. **Place the Workspace**
   - Put the `workspace` folder at the root directory (same level as `cue2ddp.exe`)
   - Ensure `cue2ddp.exe` is accessible in the parent directory of `workspace`

4. **Configure Backup Path (Optional)**
   - By default, `work.bat` uses `M:\DDP\` as the base directory for backups
   - You will be prompted to specify a subfolder name under `M:\DDP\` during execution
   - If you need a different base directory, edit `work.bat` and modify the backup path

## Usage

1. **Prepare Your Files**
   - Place your `.cue` file and corresponding `.wav` file(s) into the `workspace` folder
   - Rename your `.cue` file to `CDImage.cue`

2. **Run the Conversion**
   - Execute `work.bat` in the `workspace` folder
   - Follow the on-screen prompts step by step

3. **Complete the Process**
   - The script will:
     - Convert the CUE/WAV files to DDP format
     - Automatically rename the `SD` folder to `PQDESCR` (internal step)
     - Prompt you to specify a backup subfolder name under `M:\DDP\`
     - Move the production files to `M:\DDP\YourFolderName\`
     - Open the backup folder automatically

## Workflow Overview

```
workspace/
├── CDImage.cue          (your renamed .cue file)
├── [audio files].wav    (your audio files)
└── work.bat             (execution script)
```

After running `work.bat`, the DDP files will be generated in the `production` folder and then **moved** (not copied) to `M:\DDP\YourFolderName\`. The local `production` folder will no longer contain the files after the move operation.
