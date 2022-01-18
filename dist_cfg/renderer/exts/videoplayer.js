'use strict';

//const videos = ['mayhem.mp4', 'dynamicwater.mp4', 'pyros.mp4', 'mayhem2.mp4', 'worktobedone.mp4', 'shorewaves.mp4'];
//const videos = ['endgame.mp4', 'craterstorm.mp4', 'redcomet.mp4', 'shorewaves.mp4', 'atmospherics.mp4', 'explosions.mp4', 'pyroattack.mp4'];
const videos = ['endgame.mp4', 'craterstorm.mp4', 'pyroattack.mp4'];
const video = videos[Math.floor(Math.random() * videos.length)];
const videoplayer = document.getElementById('videoplayer');
if (videoplayer != null) {
	videoplayer.src = 'video/' + video;
}