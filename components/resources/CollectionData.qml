import QtQuick 2.15

Item {
    function getColor(shortName) {
        const alias = getAlias(shortName);
        return collectionData.metadata[alias].color
            ?? collectionData.metadata['default'].color;
    }

    function getVendorYear(shortName) {
        const alias = getAlias(shortName);
        const vendor = collectionData.metadata[alias].vendor ?? '';
        const year = collectionData.metadata[alias].year ?? '';

        return [vendor, year]
            .filter(v => { return v !== '' })
            .join(' • ');
    }

    // resolves a shortName to the filename (without .png) used in
    // assets/images/devices/ and assets/images/devicesCompact/
    function getImage(shortName) {
        const alias = getAlias(shortName);
        if (alias === 'default') return shortName;
        return collectionData.metadata[alias].image ?? alias;
    }

    // resolves a shortName to the filename (without .png) used in
    // assets/images/collections/ - falls back to the device image name
    // (and then the alias) when a platform has no dedicated collection logo
    function getCollectionImage(shortName) {
        const alias = getAlias(shortName);
        if (alias === 'default') return shortName;
        return collectionData.metadata[alias].collectionImage
            ?? collectionData.metadata[alias].image
            ?? alias;
    }

    // hasOwnProperty rather than a plain "!== undefined" lookup: these are
    // plain JS objects, so keys inherited from Object.prototype answer too. A
    // collection whose shortName happened to be 'constructor', 'toString' or
    // 'valueOf' resolved to a function, which then missed in metadata and took
    // getColor()/getVendorYear() down with a TypeError.
    function has(map, key) {
        return Object.prototype.hasOwnProperty.call(map, key);
    }

    function getAlias(shortName) {
        if (has(aliases, shortName)) return aliases[shortName];
        if (has(metadata, shortName)) return shortName;
        return 'default'
    }

    // assets/images/collections/ only has logos for some platforms; used to
    // decide whether to show a collection's logo or fall back to its text name
    property var logoImages: [
        '3ds', '32x', 'allgames', 'android', 'arcade', 'dreamcast', 'favorites',
        'fc', 'gamecube', 'gamegear', 'gb', 'gba', 'gbc', 'genesis',
        'mastersystem', 'megacd', 'megadrive', 'n64', 'nds', 'neogeo',
        'neogeocd', 'nes', 'ngp', 'ngpc', 'pcengine', 'pico8', 'ps1', 'ps2', 'psp',
        'psvita', 'recents', 'saturn', 'segacd', 'sfc', 'snes', 'tg16',
        'vboy', 'wii', 'wiiu', 'wswan', 'wswanc', 'xbox',
    ];

    function hasLogo(shortName) {
        return logoImages.indexOf(getCollectionImage(shortName)) !== -1;
    }

    property var aliases: {
        '2600': 'atari2600',
        '5200': 'atari5200',
        '7800': 'atari7800',
        'jaguar': 'atarijaguar',
        'lynx': 'atarilynx',
        'cd-i': 'cdi',
        'msdos': 'dos',
        'dc': 'dreamcast',
        'famicom': 'fc',
        'fba': 'fbneo',
        'fbn': 'fbneo',
        'gc': 'gamecube',
        'gameboy': 'gb',
        'gameboyadvance': 'gba',
        'gameboycolor': 'gbc',
        'md': 'megadrive',
        'gameandwatch': 'gw',
        'gamewatch': 'gw',
        'sms': 'mastersystem',
        'msx2': 'msx',
        'msx2+': 'msx',
        'aes': 'neogeo',
        'neogeoaes': 'neogeo',
        'pcenginecd': 'pcecd',
        'pce': 'pcengine',
        'pico-8': 'pico8',
        'ps1': 'psx',
        'sega32x': '32x',
        'mega32x': '32x',
        'superfamicom': 'sfc',
        'superfc': 'sfc',
        'sg-1000': 'sg1000',
        'supernes': 'snes',
        'turbografx16': 'tg16',
        'tg16cd': 'tgcd',
        'turbografx16cd': 'tgcd',
        'vb': 'vboy',
        'virtualboy': 'vboy',
        'vita': 'psvita',
        'wonderswan': 'wswan',
        'wonderswanc': 'wswanc',
        'wonderswancolor': 'wswanc',
        'x68k': 'x68000',

        // launchbox shortnames
        '3do interactive multiplayer': '3do',
        'nintendo 3ds': '3ds',
        'commodore amiga': 'amiga',
        'amstrad cpc': 'amstradcpc',
        'apple ii': 'apple2',
        'atari 2600': 'atari2600',
        'atari 5200': 'atari5200',
        'atari 7800': 'atari7800',
        'atari jaguar': 'atarijaguar',
        'atari lynx': 'atarilynx',
        'atari st': 'atarist',
        'sammy atomiswave': 'atomiswave',
        'commodore 64': 'c64',
        'capcom cps1': 'cps1',
        'capcom cps2': 'cps2',
        'capcom cps3': 'cps3',
        'sega dreamcast': 'dreamcast',
        'final burn alpha': 'fbneo',
        'final burn neo': 'fbneo',
        'nintendo famicom disk system': 'fds',
        'nintendo gamecube': 'gamecube',
        'sega game gear': 'gamegear',
        'nintendo game boy': 'gb',
        'nintendo game boy advance': 'gba',
        'nintendo game boy color': 'gbc',
        'sega genesis': 'genesis',
        'sega mega drive': 'megadrive',
        'mattel intellivision': 'intellivision',
        'sega master system': 'mastersystem',
        'microsoft msx': 'msx',
        'microsoft msx2': 'msx',
        'nintendo 64': 'n64',
        'nintendo ds': 'nds',
        'nintendo entertainment system': 'nes',
        'snk neo geo aes': 'neogeo',
        'snk neo geo mvs': 'neogeo',
        'snk neo geo cd': 'neogeocd',
        'snk neo geo pocket': 'ngp',
        'snk neo geo pocket color': 'ngpc',
        'nec pc-fx': 'pcfx',
        'sony playstation 2': 'ps2',
        'sony psp': 'psp',
        'sony playstation': 'psx',
        'sony playstation vita': 'psvita',
        'sega saturn': 'saturn',
        'sega 32x': '32x',
        'sega cd': 'megacd',
        'sega sg-1000': 'sg1000',
        'super nintendo entertainment system': 'snes',
        'pc engine supergrafx': 'supergrafx',
        'nec turbografx-16': 'tg16',
        'gce vectrex': 'vectrex',
        'nintendo wii': 'wii',
        'nintendo wii u': 'wiiu',
        'sinclair zx spectrum': 'zxspectrum',
    }

    property var metadata: {
        '3do': { color: '#afdb69', vendor: 'The 3DO Company', year: '1993-1996' },
        '3ds': { color: '#73bc9e', vendor: 'Nintendo', year: '2011-2020' },
        '32x': { color: '#edc42d', vendor: 'Sega', year: '1994-1996', image: 'segacd', collectionImage: '32x' },
        'allgames': { color: '#3c556e' },
        'amiga': { color: '#724755', vendor: 'Commodore', year: '1985-1996' },
        'amstradcpc': { color: '#3a7d44', vendor: 'Amstrad', year: '1984-1990' },
        'android': { color: '#266f4f' },
        'apple2': { color: '#8fce00', vendor: 'Apple', year: '1977-1993' },
        'arcade': { color: '#502087' },
        'atari2600': { color: '#4f7524', vendor: 'Atari', year: '1977-1992' },
        'atari5200': { color: '#0685bb', vendor: 'Atari', year: '1982-1984' },
        'atari7800': { color: '#1d4b4c', vendor: 'Atari', year: '1986-1992' },
        'atarijaguar': { color: '#af4bec', vendor: 'Atari', year: '1993-1996' },
        'atarilynx': { color: '#4c9141', vendor: 'Atari', year: '1989-1995' },
        'atarist': { color: '#2f5d8a', vendor: 'Atari', year: '1985-1993' },
        'atomiswave': { color: '#025669', vendor: 'Sammy', year: '2003-2009', image: 'arcade' },
        'c64': { color: '#9d4083', vendor: 'Commodore', year: '1982-1994' },
        'cdi': { color: '#1349ca', vendor: 'Philips', year: '1990-1998' },
        'colecovision': { color: '#f9182f', vendor: 'Coleco', year: '1982-1985' },
        'cps1': { color: '#025836', vendor: 'Capcom', year: '1988-1995', image: 'arcade' },
        'cps2': { color: '#049728', vendor: 'Capcom', year: '1993-2003', image: 'arcade' },
        'cps3': { color: '#258ed1', vendor: 'Capcom', year: '1996-1999', image: 'arcade' },
        'default': { color: '#194492' },
        'dos': { color: '#87151b', vendor: 'Microsoft', year: '1981-2000' },
        'dreamcast': { color: '#2387ff', vendor: 'Sega', year: '1998-2001', image: 'dreamcast' },
        'fc': { color: '#7A1E2C', vendor: 'Nintendo', year: '1983-2003', image: 'fc' },
        'favorites': { color: '#b75057' },
        'fbneo': { color: '#502087', image: 'arcade' },
        'fds': { color: '#191a49', vendor: 'Nintendo', year: '1986-1990', image: 'fc' },
        'gamecube': { color: '#4b0082', vendor: 'Nintendo', year: '2001-2007', image: 'gamecube' },
        'gamegear': { color: '#1f6363', vendor: 'Sega', year: '1990-1997', image: 'gamegear' },
        'gb': { color: '#81ad72', vendor: 'Nintendo', year: '1989-2003', image: 'gb' },
        'gba': { color: '#264491', vendor: 'Nintendo', year: '2001-2008', image: 'gba' },
        'gbc': { color: '#452491', vendor: 'Nintendo', year: '1998-2003', image: 'gbc' },
        'genesis': { color: '#0c49cc', vendor: 'Sega', year: '1988-1997', image: 'genesis' },
        'gw': { color: '#6f3e80', vendor: 'Nintendo', year: '1980-1991' },
        'intellivision': { color: '#4566f5', vendor: 'Mattel', year: '1979-1990' },
        'mame': { color: '#082f72', image: 'arcade' },
        'mastersystem': { color: '#673d3f', vendor: 'Sega', year: '1985-1996', image: 'mastersystem' },
        'megacd': { color: '#cc4545', vendor: 'Sega', year: '1991-1996', image: 'segacd', collectionImage: 'megacd' },
        'megadrive': { color: '#0c49cc', vendor: 'Sega', year: '1988-1997', image: 'megadrive' },
        'msx': { color: '#ef3208', vendor: 'Microsoft', year: '1983-1993' },
        'mvs': { color: '#851d01', vendor: 'SNK', year: '1990-1997', image: 'arcade' },
        'n64': { color: '#069330', vendor: 'Nintendo', year: '1996-2002', image: 'n64' },
        'naomi': { color: '#843c8a', vendor: 'Sega', year: '1998-2001', image: 'arcade' },
        'nds': { color: '#869299', vendor: 'Nintendo', year: '2004-2013', image: 'nds' },
        'neogeo': { color: '#1499de', vendor: 'SNK', year: '1990-2004' },
        'neogeocd': { color: '#9e5c27', vendor: 'SNK', year: '1994-1997', image: 'neogeocd' },
        'nes': { color: '#7A1E2C', vendor: 'Nintendo', year: '1983-2003', image: 'nes' },
        'ngp': { color: '#b32428', vendor: 'SNK', year: '1998-1999', image: 'ngpc', collectionImage: 'ngp' },
        'ngpc': { color: '#b42929', vendor: 'SNK', year: '1999-2001', image: 'ngpc' },
        'odyssey2': { color: '#9b276d', vendor: 'Magnavox', year: '1978-1984' },
        'pcecd': { color: '#6c8156', vendor: 'NEC', year: '1988-1994', image: 'pcengine' },
        'pcengine': { color: '#25482b', vendor: 'NEC', year: '1987-1994', image: 'pcengine' },
        'pcfx': { color: '#7a1e5a', vendor: 'NEC', year: '1994-1998' },
        'pico8': { color: '#1c542d', vendor: 'Lexaloffle', year: '2015', image: 'pico8' },
        'pokemini': { color: '#19b091', vendor: 'Nintendo', year: '2001-2002' },
        'ports': { color: '#1d334a' },
        'ps2': { color: '#347867', vendor: 'Sony', year: '2000-2013', image: 'ps2' },
        'psp': { color: '#2d4080', vendor: 'Sony', year: '2004-2014', image: 'psp' },
        'psvita': { color: '#2d4080', vendor: 'Sony', year: '2011-2019', image: 'psp', collectionImage: 'psvita' },
        'psx': { color: '#1f346b', vendor: 'Sony', year: '1994-2006', image: 'ps1' },
        'recents': { color: '#906226', vendor: '' },
        'saturn': { color: '#5b92ff', vendor: 'Sega', year: '1994-2000', image: 'saturn' },
        'scummvm': { color: '#5bce20', vendor: 'Lucasfilm Games', year: '1987-1998' },
        'segacd': { color: '#cc4545', vendor: 'Sega', year: '1991-1996', image: 'segacd' },
        'sfc': { color: '#766f81', vendor: 'Nintendo', year: '1990-2003', image: 'sfc' },
        'sg1000': { color: '#0c8427', vendor: 'Sega', year: '1983-1985' },
        'snes': { color: '#aa6aff', vendor: 'Nintendo', year: '1990-2003', image: 'snes' },
        'supergrafx': { color: '#a66637', vendor: 'NEC', year: '1989-1990' },
        'tg16': { color: '#585f21', vendor: 'NEC', year: '1987-1994', image: 'tg16' },
        'tgcd': { color: '#340f7a', vendor: 'NEC', year: '1988-1994', image: 'pcengine' },
        'vboy': { color: '#802325', vendor: 'Nintendo', year: '1995-1996' },
        'vectrex': { color: '#8129f1', vendor: 'Milton Bradley', year: '1982-1984', image: 'vboy' },
        'wii': { color: '#e0e027', vendor: 'Nintendo', year: '2006-2017', image: 'wii' },
        'wiiu': { color: '#4b0082', vendor: 'Nintendo', year: '2012-2017', image: 'wiiu' },
        'wswan': { color: '#d38aba', vendor: 'Bandai', year: '1999-2003', image: 'wswan' },
        'wswanc': { color: '#9b3f23', vendor: 'Bandai', year: '1999-2003', image: 'wswan', collectionImage: 'wswanc' },
        'x68000': { color: '#a53180', vendor: 'Sharp', year: '1987-1993' },
        'xbox': { color: '#0c46a9', vendor: 'Microsoft', year: '2001-2006', image: 'xbox' },
        'zxspectrum': { color: '#0c46a9', vendor: 'Sinclair', year: '1982-1992' },
    };
}
