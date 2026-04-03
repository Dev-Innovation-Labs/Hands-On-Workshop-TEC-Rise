#!/usr/bin/env node
/**
 * server.js - Bootstrap CAP server tanpa TTY (bisa dijalankan sebagai daemon)
 * Jalankan: node server.js
 *
 * Endpoints:
 *   http://localhost:4004/catalog/Books       — OData API
 *   http://localhost:4004/books/webapp/standalone.html — Fiori App
 */
'use strict';

// Pastikan working directory = folder project ini
process.chdir(__dirname);

const path = require('path');
const cds  = require('@sap/cds');

cds.on('bootstrap', app => {
    const express = require('express');

    // Sajikan Fiori app di /books/webapp/
    app.use('/books/webapp', express.static(
        path.join(__dirname, 'app/books/webapp')
    ));

    // Health check
    app.get('/health', (req, res) => {
        res.json({ status: 'UP', timestamp: new Date().toISOString() });
    });
});

const cds_server = require('@sap/cds/server');

// Gunakan port dari env atau default 4004
const port = process.env.PORT || 4004;

cds_server({ service: 'all', port })
    .then(srv => {
        const p = port;
        console.log('[server] ✅ Server berjalan!');
        console.log('[server] 📡 OData API : http://localhost:' + p + '/catalog/Books');
        console.log('[server] 🎨 Fiori App : http://localhost:' + p + '/books/webapp/standalone.html');
    })
    .catch(err => { console.error('[server] FAILED:', err.message); process.exit(1); });
