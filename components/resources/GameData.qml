import QtQuick 2.15

Item {
    property string genreText: {
        if (!currentGame) return '';
        if (!currentGame.genreList || currentGame.genreList.length === 0) { return ''; }

        const genre = currentGame.genreList[0] ?? '';
        const split = genre.split(',');

        // '' rather than null: this is a `property string`, so null would
        // be coerced anyway, and every other branch here returns ''
        if (split[0].length === 0) { return ''; }

        return split[0];
    }

    property string releaseDateText: {
        if (!currentGame) return '';
        if (!currentGame.releaseYear) return '';

        return 'Released ' + currentGame.releaseYear;
    }

    property string playersText: {
        if (!currentGame) return '';
        if (currentGame.players === 1) return '1 player';

        return currentGame.players + ' players';
    }

    property var ratingText: {
        if (!currentGame) return '';
        if (currentGame.rating === 0) return '';

        let stars = [];
        const rating = Math.round(currentGame.rating * 500) / 100;

        for (let i = 0; i < 5; i++) {
            if (rating - i <= 0) {
                stars.push(glyphs.emptyStar);
            } else if (rating - i < 1) {
                stars.push(glyphs.halfStar);
            } else {
                stars.push(glyphs.fullStar);
            }
        }

        return stars.join(' ');
    }

    property string developedByText: {
        if (!currentGame) return '';

        if (currentGame.developer) {
            return 'Dev\'d by ' + currentGame.developer;
        }

        if (currentGame.publisher) {
            return 'Pub\'d by ' + currentGame.publisher;
        }

        return '';
    }
}
