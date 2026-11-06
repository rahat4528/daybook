@echo off
echo Starting DayBook Luxury Website (GeoAxis Aesthetic)...
cd "%~dp0website"
start "" http://localhost:3000
node server.js
pause
