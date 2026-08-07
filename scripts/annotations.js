#!/usr/bin/env node
// Emits GitHub error annotations for failures in a juliati results JSON
// (TestItemControllers.Results format). Dependency-free; missing or unreadable
// input is treated as "nothing to annotate" so this never fails the job itself.
'use strict';
const fs = require('fs');
const path = require('path');

// GitHub displays at most 10 error annotations per step.
const MAX_ANNOTATIONS = 10;

function esc(s) {
    return String(s).replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
}

function escProp(s) {
    return esc(s).replace(/:/g, '%3A').replace(/,/g, '%2C');
}

function uriToRelPath(uri) {
    if (!uri || !uri.startsWith('file://')) return null;
    let p;
    try {
        p = decodeURIComponent(uri.replace(/^file:\/\//, ''));
    } catch {
        return null;
    }
    // Windows URIs look like file:///C:/...
    if (/^\/[a-zA-Z]:[/\\]/.test(p)) p = p.slice(1);
    const ws = process.env.GITHUB_WORKSPACE;
    if (ws) {
        const rel = path.relative(ws, p);
        if (!rel.startsWith('..') && !path.isAbsolute(rel)) return rel.split(path.sep).join('/');
    }
    return p;
}

function emit(a) {
    const props = [];
    if (a.file) props.push(`file=${escProp(a.file)}`);
    if (a.line) props.push(`line=${escProp(a.line)}`);
    if (a.title) props.push(`title=${escProp(a.title)}`);
    console.log(`::error ${props.join(',')}::${esc(a.message)}`);
}

const resultsFile = process.argv[2];
if (!resultsFile || !fs.existsSync(resultsFile)) process.exit(0);

let result;
try {
    result = JSON.parse(fs.readFileSync(resultsFile, 'utf8'));
} catch {
    process.exit(0);
}

const annotations = [];

for (const de of result.definition_errors ?? []) {
    annotations.push({
        file: uriToRelPath(de.uri),
        line: de.line,
        title: 'Test definition error',
        message: de.message,
    });
}

for (const ti of result.testitems ?? []) {
    for (const profile of ti.profiles ?? []) {
        if (profile.status === 'passed' || profile.status === 'skipped') continue;
        const msg = profile.messages?.[0];
        annotations.push({
            file: uriToRelPath(msg?.uri || ti.uri),
            line: msg?.line,
            title: `Test item "${ti.name}" ${profile.status}`,
            message: msg?.message || `Test item ${profile.status}.`,
        });
    }
}

for (const a of annotations.slice(0, MAX_ANNOTATIONS)) emit(a);
if (annotations.length > MAX_ANNOTATIONS) {
    const hidden = annotations.length - MAX_ANNOTATIONS;
    console.log(`::notice::${esc(`${hidden} further test failure(s) not annotated — see the job log.`)}`);
}
