<?php

declare(strict_types=1);

// Managed by bootstrap. Rector with broad upgrade + quality sets (§11.7).
// CI runs this in --dry-run; apply fixes locally with `make rector-fix`.

use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src'])
    ->withPhpSets(php84: true)
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        codingStyle: true,
        typeDeclarations: true,
        privatization: true,
        naming: true,
        instanceOf: true,
        earlyReturn: true,
        strictBooleans: true,
    );
