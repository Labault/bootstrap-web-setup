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
			__DIR__ . '/wp-activate.php',
			__DIR__ . '/wp-blog-header.php',
			__DIR__ . '/wp-comments-post.php',
			__DIR__ . '/wp-config.php',
			__DIR__ . '/wp-cron.php',
			__DIR__ . '/wp-links-opml.php',
			__DIR__ . '/wp-load.php',
			__DIR__ . '/wp-login.php',
			__DIR__ . '/wp-mail.php',
			__DIR__ . '/wp-settings.php',
			__DIR__ . '/wp-signup.php',
			__DIR__ . '/wp-trackback.php',
			__DIR__ . '/wp-content/cache',
			__DIR__ . '/wp-content/languages',
			__DIR__ . '/wp-content/upgrade',
			__DIR__ . '/wp-content/uploads',
			__DIR__ . '/wp-includes',
			__DIR__ . '/xmlrpc.php',
		]
	);
