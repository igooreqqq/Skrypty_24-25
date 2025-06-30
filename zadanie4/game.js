
const config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 350 },
            debug: false
        }
    },
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

let player;
let platforms;
let cursors;
let enemies;
let lives = 3;
let livesText;
let gameOverText;
let isGameOver = false;

const game = new Phaser.Game(config);


function preload() {
    this.load.image('sky', 'https://labs.phaser.io/assets/skies/space3.png');
    this.load.image('ground', 'https://labs.phaser.io/assets/sprites/platform.png');
    this.load.image('enemy', 'https://labs.phaser.io/assets/sprites/space-baddie.png');
    this.load.spritesheet('dude',
        'https://labs.phaser.io/assets/sprites/dude.png',
        { frameWidth: 32, frameHeight: 48 }
    );
}

function create() {
    this.add.image(400, 300, 'sky');

    platforms = this.physics.add.staticGroup();

    platforms.create(400, 568, 'ground').setScale(2).refreshBody();

    platforms.create(600, 400, 'ground');
    platforms.create(50, 250, 'ground');
    platforms.create(750, 220, 'ground');

    player = this.physics.add.sprite(100, 450, 'dude');
    player.setBounce(0.2);
    player.setCollideWorldBounds(true);

    this.anims.create({
        key: 'left',
        frames: this.anims.generateFrameNumbers('dude', { start: 0, end: 3 }),
        frameRate: 10,
        repeat: -1
    });

    this.anims.create({
        key: 'turn',
        frames: [{ key: 'dude', frame: 4 }],
        frameRate: 20
    });

    this.anims.create({
        key: 'right',
        frames: this.anims.generateFrameNumbers('dude', { start: 5, end: 8 }),
        frameRate: 10,
        repeat: -1
    });

    cursors = this.input.keyboard.createCursorKeys();

    enemies = this.physics.add.group();
    
    const enemy1 = enemies.create(500, 365, 'enemy');
    enemy1.setBounce(1);
    enemy1.setCollideWorldBounds(true);
    enemy1.setVelocityX(-50);

    const enemy2 = enemies.create(700, 185, 'enemy');
    enemy2.setBounce(1);
    enemy2.setCollideWorldBounds(true);
    enemy2.setVelocityX(50);

    this.physics.add.collider(player, platforms);
    this.physics.add.collider(enemies, platforms);
    this.physics.add.collider(player, enemies, hitEnemy, null, this);

    livesText = this.add.text(16, 16, 'Życia: 3', { fontSize: '32px', fill: '#FFF' });
    
    gameOverText = this.add.text(400, 300, 'GAME OVER', { fontSize: '64px', fill: '#F00' });
    gameOverText.setOrigin(0.5);
    gameOverText.setVisible(false);
}


function update() {
    if (isGameOver) {
        return;
    }

    if (player.y > this.sys.game.config.height) {
        playerDied.call(this);
    }

    if (cursors.left.isDown) {
        player.setVelocityX(-160);
        player.anims.play('left', true);
    } else if (cursors.right.isDown) {
        player.setVelocityX(160);
        player.anims.play('right', true);
    } else {
        player.setVelocityX(0);
        player.anims.play('turn');
    }

    if (cursors.up.isDown && player.body.touching.down) {
        player.setVelocityY(-330);
    }
}

/**
 * 
 * @param {Phaser.Physics.Arcade.Sprite} player
 * @param {Phaser.Physics.Arcade.Sprite} enemy
 */
function hitEnemy(player, enemy) {
    if (player.body.velocity.y > 0 && player.body.bottom < enemy.body.y + 10) {
        enemy.disableBody(true, true);
        player.setVelocityY(-200);
    } else {
        playerDied.call(this);
    }
}

function playerDied() {
    if (player.isDying) return;

    player.isDying = true;
    lives--;
    livesText.setText('Życia: ' + lives);

    this.cameras.main.shake(250, 0.01);
    player.setTint(0xff0000);

    if (lives > 0) {
        this.time.delayedCall(1000, () => {
            player.clearTint();
            player.setPosition(100, 450);
            player.setVelocity(0, 0);
            player.isDying = false;
        }, [], this);
    } else {
        isGameOver = true;
        this.physics.pause();
        player.setTint(0xff0000);
        player.anims.play('turn');
        gameOverText.setVisible(true);
    }
}

let stars;
let score = 0;
let scoreText;

const oldCreate = create;
create = function() {
    oldCreate.call(this);

    stars = this.physics.add.group({
        key: 'star',
        repeat: 11,
        setXY: { x: 12, y: 0, stepX: 70 }
    });

    stars.children.iterate(function (child) {
        child.setBounceY(Phaser.Math.FloatBetween(0.4, 0.8));
    });

    this.physics.add.collider(stars, platforms);
    this.physics.add.overlap(player, stars, collectStar, null, this);

    scoreText = this.add.text(16, 16, 'Score: 0', { fontSize: '32px', fill: '#fff' });

}

const oldUpdate = update;
update = function() {
    oldUpdate.call(this);

    if (player.y > 600 && !isGameOver) {
        loseLife(this);
    }
}

function collectStar (player, star) {
    star.disableBody(true, true);

    score += 10;
    scoreText.setText('Score: ' + score);
}

function loseLife(scene) {
    lives -= 1;
    livesText.setText('Lives: ' + lives);

    if (lives <= 0) {
        scene.physics.pause();
        player.setTint(0xff0000);
        player.anims.play('turn');
        gameOverText.setText('Game Over!');
        isGameOver = true;
    } else {
        player.setPosition(100, 450);
    }
}

const oldPreload = preload;
preload = function() {
    oldPreload.call(this);
    this.load.image('star', 'https://labs.phaser.io/assets/demoscene/star.png');
};
