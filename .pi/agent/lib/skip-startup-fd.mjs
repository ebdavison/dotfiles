import { createRequire, syncBuiltinESMExports } from 'node:module';

if (process.env.PI_SKIP_STARTUP_FD === '1') {
  const require = createRequire(import.meta.url);
  const childProcess = require('node:child_process');
  const originalSpawnSync = childProcess.spawnSync;

  childProcess.spawnSync = function patchedSpawnSync(command, args, options) {
    const argv = Array.isArray(args) ? args : [];
    const isFdVersionProbe =
      (command === 'fd' || command === 'fdfind') &&
      argv.length === 1 &&
      argv[0] === '--version';

    if (isFdVersionProbe) {
      return {
        pid: 0,
        output: [null, Buffer.from('fd 0\n'), Buffer.alloc(0)],
        stdout: Buffer.from('fd 0\n'),
        stderr: Buffer.alloc(0),
        status: 0,
        signal: null,
        error: undefined,
      };
    }

    return originalSpawnSync.call(this, command, args, options);
  };

  syncBuiltinESMExports();
}
