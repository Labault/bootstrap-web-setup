<?php

declare(strict_types=1);

// Managed by bootstrap (wordpress profile). Rector upgrades project-owned code
// while WordPress core, dependencies and mutable content remain out of scope.

use Rector\Config\RectorConfig;

return RectorConfig::configure()
	->withPaths([__DIR__])
	->withPhpSets(php83: true)
	->withPreparedSets(
		codeQuality: true,
		deadCode: true,
		earlyReturn: true,
		instanceOf: true,
		naming: true,
		privatization: true,
		typeDeclarations: true,
	)
	->withSkip(
		[
			__DIR__ . '/index.php',
			__DIR__ . '/node_modules',
			__DIR__ . '/vendor',
			__DIR__ . '/wp-admin',
			__DIR__ . '/wp-*.php',
			__DIR__ . '/wp-content/cache',
			__DIR__ . '/wp-content/languages',
			__DIR__ . '/wp-content/upgrade',
			__DIR__ . '/wp-content/uploads',
			__DIR__ . '/wp-includes',
			__DIR__ . '/xmlrpc.php',
		]
	);
