'use strict';

const images = ['1.png', '2.png', '3.png'];
const image = images[Math.floor(Math.random() * images.length)];
document.getElementById('randomimages').src = 'images/backgrounds/' + image;