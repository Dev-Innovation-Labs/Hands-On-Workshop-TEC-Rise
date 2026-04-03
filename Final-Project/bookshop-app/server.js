#!/usr/bin/env node
/**
 * server.js - Bootstrap CAP server tanpa TTY (bisa dijalankan sebagai daemon)
 * Jalankan: node server.js
 */
'use strict';

// Pastikan working directory = folder project ini
process.chdir(__dirname);

const cds_server = require('@sap/cds/server');

cds_server({ service: 'all' })
    .then(srv => console.log('[server] Listening at', srv.url))
    .catch(err => { console.error('[server] FAILED:', err.message); process.exit(1); });
