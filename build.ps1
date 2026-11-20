# =============================================================================
#  Aarush Suzuki static site builder (Windows PowerShell 5.1+, no Node needed)
#
#  src/data/*.json        site settings, vehicles (specs, colours, features), showrooms
#  src/partials/*.html    shared <head>, header and footer
#  src/pages/*.html       page bodies with a <!-- meta --> block and {{TOKENS}}
#  build.ps1 -> site/     every page as /path/index.html, plus data.js, sitemap, redirects
#
#  Usage:  powershell -ExecutionPolicy Bypass -File build.ps1
#  To add a new Suzuki model: add an entry to src/data/vehicles.json, put its
#  cut-out image in site/assets/img/models/, and run the build.
# =============================================================================
param([string]$Out = 'site')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root 'src'
$out = Join-Path $root $Out
$utf8 = New-Object Text.UTF8Encoding $false

function Read-Text($p) { [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }
function Write-Text($p, $t) {
  $d = Split-Path $p
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
  [IO.File]::WriteAllText($p, $t, $utf8)
}
function Enc($s) { [System.Net.WebUtility]::HtmlEncode([string]$s) }
function Clip($t) {
  # end feature copy on a complete sentence (source text is length-limited)
  $t = ([string]$t).Trim()
  if ($t -match '[.!?)]$') { return $t }
  $i = $t.LastIndexOf('. ')
  if ($i -gt 40) { return $t.Substring(0, $i + 1) }
  $j = $t.LastIndexOf(' ')
  if ($j -lt 1) { return $t }
  return $t.Substring(0, $j).TrimEnd(',', ';', ':', ' ') + '…'
}
function Phone($n) { "$($n.Substring(0,5)) $($n.Substring(5))" }
function JsonStr($s) { '"' + ([string]$s).Replace('\', '\\').Replace('"', '\"') + '"' }

$site      = Read-Text "$src/data/site.json" | ConvertFrom-Json
$vehRaw    = Read-Text "$src/data/vehicles.json"
$showRaw   = Read-Text "$src/data/showrooms.json"
$siteRaw   = Read-Text "$src/data/site.json"
$vehicles  = $vehRaw | ConvertFrom-Json
$showrooms = $showRaw | ConvertFrom-Json
$VM = @{}; foreach ($v in $vehicles) { $VM[$v.id] = $v }
$BASE = $site.siteUrl

# Google Maps directions link to a showroom, built from its address (permanent format; replaces goo.gl short links)
function DirUrl($label, $addr) { 'https://www.google.com/maps/dir/?api=1&amp;destination=' + [Uri]::EscapeDataString("Aarush Suzuki $label, $addr") }
function WA($text) { "https://wa.me/$($site.contact.whatsapp)?text=" + [Uri]::EscapeDataString($text) }

$CAT = @{
  motorcycles = @{ label = 'Motorcycle';  plural = 'Motorcycles';       url = '/motorcycles/' }
  scooters    = @{ label = 'Scooter';     plural = 'Scooters';          url = '/scooters/' }
  electric    = @{ label = 'Electric';    plural = 'Electric Vehicles'; url = '/electric-vehicles/' }
  premium     = @{ label = 'Premium bike';plural = 'Premium Bikes';     url = '/premium-bikes/' }
}

$partHead   = Read-Text "$src/partials/head.html"
$partHeader = Read-Text "$src/partials/header.html"
$partFooter = Read-Text "$src/partials/footer.html"

# ---------------------------------------------------------------- helpers ----
function Get-Spec($v, $pattern) {
  # pattern may be "GroupRegex>RowRegex" to look inside one spec group only
  $groupPat = '.'
  if ($pattern -like '*>*') { $groupPat, $pattern = $pattern.Split('>', 2) }
  foreach ($g in $v.specs) { if ($g[0] -notmatch $groupPat) { continue }; foreach ($r in $g[1]) { if ($r[0] -match $pattern) { return $r[1] } } }
  return $null
}
function Alt($v) { "Suzuki $($v.name), side view" }
function Is-Photo($v) { $v.image -like 'http*' -or $v.image -like '*/portrait.*' }
# Lowest official Hyderabad ex-showroom price, formatted the Indian way (₹1,39,321)
function PriceFrom($v) {
  if (-not $v.prices -or $v.prices.Count -eq 0) { return '' }
  $min = ($v.prices | ForEach-Object { [int64](($_[1]) -replace '[^\d]', '') } | Measure-Object -Minimum).Minimum
  return '₹' + $min.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('en-IN'))
}
function PriceLine($v, $cls) {
  $p = PriceFrom $v
  if (-not $p) { return '' }
  "<p class=`"price-from $cls`"><span>Ex-showroom Hyderabad from</span> <strong>$p</strong></p>"
}

function Breadcrumb-JsonLd($items) {
  $list = @(); $i = 1
  foreach ($it in $items) { $list += "{`"@type`":`"ListItem`",`"position`":$i,`"name`":$(JsonStr $it[0]),`"item`":$(JsonStr ($BASE + $it[1]))}"; $i++ }
  "{`"@context`":`"https://schema.org`",`"@type`":`"BreadcrumbList`",`"itemListElement`":[" + ($list -join ',') + "]}"
}
function Script-Ld($json) { "  <script type=`"application/ld+json`">$json</script>`n" }

function Assemble($meta, $body) {
  $robots = if ($meta.robots) { $meta.robots } else { 'index, follow, max-image-preview:large, max-snippet:-1' }
  $og = if ($meta.ogImage) { if ($meta.ogImage -like 'http*') { $meta.ogImage } else { $BASE + $meta.ogImage } } else { "$BASE/assets/img/photos/hero-v-strom-sx-riders.jpg" }
  $ogAlt = if ($meta.ogAlt) { $meta.ogAlt } elseif ($meta.ogImage) { $meta.title } else { 'Riders on Suzuki V-Strom SX motorcycles' }
  $ogType = if ($meta.ogType) { $meta.ogType } else { 'website' }
  $pre = ''
  if ($meta.preload -eq 'hero-banner') {
    # Preload the banner the slider shows first (the LCP image), mobile and desktop versions by breakpoint
    $todayIso = Get-Date -Format 'yyyy-MM-dd'
    $hs = @($site.heroSlides | Where-Object { -not $_.until -or $_.until -ge $todayIso })[0]
    $pre = "  <link rel=`"preload`" as=`"image`" href=`"/assets/img/banners/$($hs.model)-mobile.jpg`" media=`"(max-width: 767px)`" fetchpriority=`"high`">`n" +
           "  <link rel=`"preload`" as=`"image`" href=`"/assets/img/banners/$($hs.model)-desktop.jpg`" media=`"(min-width: 768px)`" fetchpriority=`"high`">`n"
  } elseif ($meta.preload) { $pre = "  <link rel=`"preload`" as=`"image`" href=`"$($meta.preload)`" fetchpriority=`"high`">`n" }
  # Organization + WebSite on every page, so search and AI engines tie each page to the same business
  $jsonld = (Script-Ld (Read-Text "$src/data/home-ld.json").Trim()) + [string]$meta.jsonld
  $h = $partHead.Replace('{{TITLE}}', (Enc $meta.title)).Replace('{{DESCRIPTION}}', (Enc $meta.description)).
    Replace('{{CANONICAL}}', $BASE + $meta.path).Replace('{{ROBOTS}}', $robots).Replace('{{OG_IMAGE}}', $og).
    Replace('{{OG_TYPE}}', $ogType).Replace('{{OG_ALT}}', (Enc $ogAlt)).Replace("{{ANALYTICS}}`r`n", (Analytics-Head)).Replace("{{ANALYTICS}}`n", (Analytics-Head)).Replace('{{ANALYTICS}}', (Analytics-Head)).
    Replace('{{BODY_CLASS}}', $meta.bodyClass).Replace('{{PRELOAD}}', $pre).Replace('{{JSONLD}}', $jsonld)
  $hdr = $partHeader.Replace('{{HEADER_CLASS}}', $(if ($meta.headerClass) { ' ' + $meta.headerClass } else { '' }))
  $html = $h + "`n" + (Expand-Tokens $hdr) + "`n" + $body.Trim() + "`n`n" + (Expand-Tokens $partFooter)
  # The 404 page is served at arbitrary URLs by the host, so it keeps root-absolute links.
  if ($meta.output) { return $html.Replace('<meta charset="utf-8">', "<meta charset=`"utf-8`">`n  <meta name=`"site-root`" content=`"/`">") }
  return Relativize $html $meta.path
}

# Rewrite root-absolute URLs ("/motorcycles/", "/assets/...") to page-relative ones ("../motorcycles/"),
# so the site works on any host, in any sub-folder, and when opened straight from disk.
function Relativize($html, $path) {
  $segs = @($path.Trim('/').Split('/') | Where-Object { $_ })
  $prefix = if ($segs.Count -eq 0) { './' } else { '../' * $segs.Count }
  $html = $html.Replace('<meta charset="utf-8">', "<meta charset=`"utf-8`">`n  <meta name=`"site-root`" content=`"$prefix`">")
  return [regex]::Replace($html, '(\s(?:href|src|srcset|action|poster))="/(?!/)', "`$1=`"$prefix")
}

function Crumbs($items) {
  $parts = @()
  for ($i = 0; $i -lt $items.Count; $i++) {
    $it = $items[$i]
    if ($i -eq $items.Count - 1) { $parts += "<span aria-current=`"page`">$(Enc $it[0])</span>" }
    else { $parts += "<a href=`"$($it[1])`">$(Enc $it[0])</a>" }
  }
  "<nav class=`"crumbs`" aria-label=`"Breadcrumb`">" + ($parts -join '<i aria-hidden="true">/</i>') + "</nav>"
}

# ------------------------------------------------------- reusable blocks ----
function Stage($v, $extra) {
  if (Is-Photo $v) {
    return "<figure class=`"photo-panel $extra`"><img src=`"$($v.image)`" alt=`"$(Enc "Suzuki $($v.name) on the road")`" width=`"550`" height=`"640`"></figure>"
  }
@"
<div class="pstage $extra" aria-hidden="true">
            <div class="pstage__light"></div><div class="pstage__floor"></div>
            <div class="pstage__vehicle" data-tilt><img src="$($v.image)" alt="" width="616" height="405"></div>
            <span class="pstage__shadow"></span>
          </div>
"@
}

function Stats($v, $cls) {
  $items = ($v.highlights | ForEach-Object { "<div><dt>$(Enc $_[0])</dt><dd>$(Enc $_[1])</dd></div>" }) -join ''
  "<dl class=`"stats $cls`">$items</dl>"
}

function Render-ModelRows($cat, $groups) {
  # $groups: ordered hashtable label -> @(ids). Editorial alternating rows.
  $html = ''; $n = 0
  foreach ($label in $groups.Keys) {
    $html += "<div class=`"mrows__group`" id=`"$($label.ToLower())`"><h2 class=`"mrows__label`">$(Enc $label)</h2>"
    foreach ($id in $groups[$label]) {
      $v = $VM[$id]; $n++
      $flip = if ($n % 2 -eq 0) { ' mrow--flip' } else { '' }
      $html += @"

        <article class="mrow$flip" id="$($v.id)">
          <a class="mrow__media" href="$($v.url)" tabindex="-1" aria-hidden="true">$(Stage $v '')</a>
          <div class="mrow__body">
            <p class="mrow__tag">$(Enc $v.tagline)</p>
            <h3 class="mrow__name"><a href="$($v.url)">$(Enc $v.name)</a></h3>
            <p class="mrow__summary">$(Enc $v.summary)</p>
            $(PriceLine $v '')
            $(Stats $v 'stats--compact')
            <div class="mrow__actions">
              <a class="btn btn--ink" href="$($v.url)">Explore $(Enc $v.name)</a>
              <a class="link-arrow" href="/book-a-test-ride/?model=$($v.id)">Book a test ride</a>
            </div>
          </div>
        </article>
"@
    }
    $html += "</div>"
  }
  "<div class=`"mrows`">$html</div>"
}

function Render-Compare($ids, $rows) {
  $head = ($ids | ForEach-Object { "<th scope=`"col`"><a href=`"$($VM[$_].url)`">$(Enc $VM[$_].name)</a></th>" }) -join ''
  $body = ''
  foreach ($r in $rows) {
    $cells = ($ids | ForEach-Object { $val = Get-Spec $VM[$_] $r[1]; if (-not $val) { $val = '—' }; "<td>$(Enc ($val -split '\|')[0].Trim())</td>" }) -join ''
    $body += "<tr><th scope=`"row`">$(Enc $r[0])</th>$cells</tr>"
  }
@"
<div class="compare" tabindex="0" role="region" aria-label="Specification comparison">
          <table><thead><tr><td></td>$head</tr></thead><tbody>$body</tbody></table>
        </div>
"@
}

function Render-Features($v, $max, $cls) {
  $list = @($v.features | Select-Object -First $max)
  ($list | ForEach-Object {
    $img = if ($_[2]) { "<img src=`"$($_[2])`" alt=`"$(Enc "Suzuki $($v.name) – $($_[0])")`" loading=`"lazy`" width=`"520`" height=`"420`">" } else { '' }
    $hasImg = if ($_[2]) { ' feat--img' } else { '' }
    "<article class=`"feat$hasImg $cls`">$img<div><h3>$(Enc $_[0])</h3><p>$(Enc (Clip $_[1]))</p></div></article>"
  }) -join "`n"
}

function Render-Directory($region, $withHeading) {
  $list = @($showrooms | Where-Object { -not $region -or $_.region -eq $region })
  ($list | ForEach-Object {
    $s = $_
    $tag = if ($s.id -like 'best-value*') { 'Suzuki Best Value · Sales &amp; service' } else { 'Sales &amp; service' }
    $svc = if ($s.serviceAddress) { "<p class=`"branch__svc`"><span>Service centre</span>$(Enc $s.serviceAddress)" + " <a href=`"$(DirUrl "$($s.name) service centre" $s.serviceAddress)`" target=`"_blank`" rel=`"noopener`" aria-label=`"Directions to Aarush Suzuki $(Enc $s.name) service centre`">Directions</a>" + "</p>" } else { '' }
@"
<li class="branch" data-region="$($s.region)" id="$($s.id)">
            <div class="branch__name"><h3>$(Enc $s.name)</h3><span>$tag</span></div>
            <div class="branch__addr"><address>$(Enc $s.address)</address>$svc</div>
            <div class="branch__phones">
              <a href="tel:+91$($s.sales)"><span>Sales</span>$(Phone $s.sales)</a>
              <a href="tel:+91$($s.service)"><span>Service</span>$(Phone $s.service)</a>
            </div>
            <div class="branch__acts">
              <a class="link-arrow" href="$(DirUrl $s.name $s.address)" target="_blank" rel="noopener" aria-label="Directions to Aarush Suzuki $(Enc $s.name)">Directions</a>
              <button type="button" class="branch__map" data-map-q="$(Enc "Aarush Suzuki, $($s.address)")" data-map-name="$(Enc $s.name)">Show on map</button>
              <a class="branch__wa" href="$(WA "Hi Aarush Suzuki $($s.name), I have a question.")" target="_blank" rel="noopener">WhatsApp</a>
            </div>
          </li>
"@
  }) -join "`n"
}

function Showrooms-JsonLd {
  $items = foreach ($s in $showrooms) {
    $pc = if ($s.address -match '(\d{6})\s*$') { $Matches[1] } else { '' }
    $loc = if ($s.region -eq 'hyderabad') { 'Hyderabad' } else { $s.name }
    "{`"@type`":`"MotorcycleDealer`",`"name`":$(JsonStr "Aarush Suzuki $($s.name)"),`"brand`":{`"@type`":`"Brand`",`"name`":`"Suzuki`"},`"telephone`":$(JsonStr "+91-$($s.sales)"),`"url`":$(JsonStr "$BASE/contact/#$($s.id)"),`"hasMap`":$(JsonStr ((DirUrl $s.name $s.address).Replace('&amp;','&'))),`"address`":{`"@type`":`"PostalAddress`",`"streetAddress`":$(JsonStr $s.address),`"addressLocality`":$(JsonStr $loc),`"addressRegion`":`"Telangana`",`"postalCode`":$(JsonStr $pc),`"addressCountry`":`"IN`"}}"
  }
  "{`"@context`":`"https://schema.org`",`"@graph`":[" + ($items -join ',') + "]}"
}

# Local SEO for the Services page: one AutoRepair entry per service centre (service address and service line where known)
function Services-JsonLd {
  $items = foreach ($s in $showrooms) {
    $addr = if ($s.serviceAddress) { $s.serviceAddress } else { $s.address }
    $pc = if ($addr -match '(\d{6})\s*\.?$') { $Matches[1] } else { '' }
    $loc = if ($s.region -eq 'hyderabad') { 'Hyderabad' } else { $s.name }
    "{`"@type`":`"AutoRepair`",`"name`":$(JsonStr "Aarush Suzuki $($s.name) Service Centre"),`"brand`":{`"@type`":`"Brand`",`"name`":`"Suzuki`"},`"telephone`":$(JsonStr "+91-$($s.service)"),`"url`":$(JsonStr "$BASE/services/"),`"hasMap`":$(JsonStr ((DirUrl "$($s.name) service centre" $addr).Replace('&amp;','&'))),`"address`":{`"@type`":`"PostalAddress`",`"streetAddress`":$(JsonStr $addr),`"addressLocality`":$(JsonStr $loc),`"addressRegion`":`"Telangana`",`"postalCode`":$(JsonStr $pc),`"addressCountry`":`"IN`"}}"
  }
  "{`"@context`":`"https://schema.org`",`"@graph`":[" + ($items -join ',') + "]}"
}

function Render-Selector($ids) {
  $tabs = ''; $panels = ''; $i = 0
  foreach ($id in $ids) {
    $v = $VM[$id]; $sel = if ($i -eq 0) { 'true' } else { 'false' }; $hidden = if ($i -eq 0) { '' } else { ' hidden' }; $i++
    $tabs += "<button type=`"button`" role=`"tab`" id=`"tab-$id`" aria-controls=`"panel-$id`" aria-selected=`"$sel`" data-select=`"$id`"><span>$(Enc $v.name)</span><small>$(Enc $v.tagline)</small></button>"
    $feats = (@($v.features | Select-Object -First 3) | ForEach-Object { "<li>$(Enc $_[0])</li>" }) -join ''
    $panels += @"

          <div class="selector__panel" role="tabpanel" id="panel-$id" aria-labelledby="tab-$id"$hidden>
            <div class="selector__stage">$(Stage $v '')</div>
            <div class="selector__info">
              <h3>$(Enc $v.name)</h3>
              <p>$(Enc $v.summary)</p>
              $(PriceLine $v '')
              $(Stats $v 'stats--compact')
              <ul class="ticks">$feats</ul>
              <div class="mrow__actions">
                <a class="btn btn--ink" href="$($v.url)">Explore $(Enc $v.name)</a>
                <a class="link-arrow" href="/book-a-test-ride/?model=$id">Book a test ride</a>
              </div>
            </div>
          </div>
"@
  }
@"
<div class="selector" data-selector>
          <div class="selector__tabs" role="tablist" aria-label="Choose a scooter">$tabs</div>
          $panels
        </div>
"@
}

function Render-RideForm($title, $note, $mode, $preset) {
  # mode: 'ride' (test ride) | 'service' | 'contact'
  $extra = ''
  if ($mode -eq 'service') {
    $extra = @"
<div class="form-row">
            <label class="field"><span>Registration number <em>(optional)</em></span><input name="reg" type="text" autocomplete="off" maxlength="14"><small class="field__error" aria-live="polite"></small></label>
            <label class="field"><span>Service needed</span>
              <select name="type" required><option value="">Choose a service</option><option>Periodic maintenance</option><option>Repair or inspection</option><option>Free service (new vehicle)</option><option>Accessories or parts</option><option>Other</option></select>
              <small class="field__error" aria-live="polite"></small></label>
          </div>
"@
  }
  if ($mode -eq 'contact') {
    $extra = @"
<label class="field"><span>How can we help?</span>
            <select name="type" required><option value="">Choose a topic</option><option>Buying a new vehicle</option><option>On-road price</option><option>Availability and booking</option><option>Test ride</option><option>Service</option><option>Accessories</option><option>Finance or insurance</option><option>Something else</option></select>
            <small class="field__error" aria-live="polite"></small></label>
          <label class="field"><span>Message <em>(optional)</em></span><textarea name="message" rows="3" maxlength="600"></textarea><small class="field__error" aria-live="polite"></small></label>
"@
  }
  $vehicleLabel = if ($mode -eq 'service') { 'Your vehicle' } else { 'Vehicle of interest' }
  $showroomLabel = if ($mode -eq 'service') { 'Service centre' } else { 'Preferred showroom' }
  $dateBlock = if ($mode -eq 'contact') { '' } else { "<label class=`"field`"><span>Preferred date</span><input name=`"date`" type=`"date`" required data-date-min><small class=`"field__error`" aria-live=`"polite`"></small></label>" }
  $vehReq = if ($mode -eq 'contact') { '' } else { ' required' }
  $submit = switch ($mode) { 'service' { 'Request a service slot' } 'contact' { 'Send enquiry' } default { 'Submit enquiry' } }
@"
<form class="ride-form glass glass--dark" data-ride-form data-mode="$mode"$(if ($preset) { " data-preset=`"$preset`"" }) novalidate>
          $(if ($title) { "<h2 class=`"ride-form__title`">$title</h2>" })
          <div class="form-row">
            <label class="field"><span>Full name</span><input name="name" type="text" autocomplete="name" required minlength="2"><small class="field__error" aria-live="polite"></small></label>
            <label class="field"><span>Mobile number</span><span class="field__tel"><i>+91</i><input name="phone" type="tel" inputmode="numeric" autocomplete="tel-national" required pattern="[6-9][0-9]{9}" maxlength="10"></span><small class="field__error" aria-live="polite"></small></label>
          </div>
          <label class="field"><span>$vehicleLabel</span><select name="vehicle"$vehReq data-vehicle-select><option value="">Choose a vehicle</option></select><small class="field__error" aria-live="polite"></small></label>
          $extra
          <div class="form-row">
            <label class="field"><span>$showroomLabel</span><select name="showroom" required data-showroom-select><option value="">Choose a location</option></select><small class="field__error" aria-live="polite"></small></label>
            $dateBlock
          </div>
          <button class="btn btn--red btn--block" type="submit">$submit</button>
          <p class="ride-form__note" data-form-note>$note</p>
          <p class="ride-form__error" role="alert" hidden data-form-error></p>
          <div class="ride-form__done" hidden role="status" aria-live="polite">
            <strong data-done-title></strong>
            <p data-done-text></p>
            <a class="btn btn--light ride-form__wa" data-done-wa href="https://wa.me/$($site.contact.whatsapp)" target="_blank" rel="noopener" hidden>Open WhatsApp</a>
            <button class="link-arrow link-arrow--light" type="button" data-form-reset>Start a new request</button>
          </div>
        </form>
"@
}

# ------------------------------------------------- SEO / AEO helpers ----
# Names people type in searches ("Access 125", "Gixxer 155"); used in titles, descriptions and FAQs.
$ALIAS = @{ 'gixxer' = 'Gixxer 155'; 'access' = 'Access 125'; 'avenis' = 'Avenis 125'; 'v-strom-sx' = 'V-Strom SX 250' }
function AliasOf($v) { if ($ALIAS[$v.id]) { $ALIAS[$v.id] } else { $v.name } }
function PriceNums($v) { @($v.prices | ForEach-Object { [int64](($_[1]) -replace '[^\d]', '') }) }
function Rupees($n) { '₹' + ([int64]$n).ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('en-IN')) }
function HL($v, $label) { foreach ($h in $v.highlights) { if ($h[0] -eq $label) { return (($h[1] -split ' @ ')[0]).Trim() } }; return $null }
function PriceDate($v) { if ($v.pricesNote -match 'on (\d{1,2} \w+ \d{4})') { $Matches[1] } else { '' } }

function Model-Title($v) {
  $a = AliasOf $v
  if (-not $v.prices -or -not $v.prices.Count) { return "Suzuki $a in Hyderabad – Specs | Aarush Suzuki" }
  $extra = if ($v.category -eq 'electric') { 'Range' } else { 'Specs' }
  $t = "Suzuki $a Price in Hyderabad & $extra | Aarush Suzuki"
  if ($t.Length -gt 60) { $t = "Suzuki $a Price in Hyderabad | Aarush Suzuki" }
  return $t
}
function Model-Description($v) {
  $a = AliasOf $v; $nc = @($v.colours).Count
  $spec = if ($v.category -eq 'electric') { "$(HL $v 'Range (AIS 040)') certified range (AIS 040), $nc colours" }
          else { "$(HL $v 'Displacement'), $(@((HL $v 'Max power'), (HL $v 'Gearbox')) | Where-Object { $_ } | Select-Object -First 1), $nc colours" }
  if ($v.prices -and $v.prices.Count) {
    $nums = PriceNums $v
    $lead = if ($nums.Count -gt 1) { "from $(Rupees (($nums | Measure-Object -Minimum).Minimum))" } else { ": $(Rupees $nums[0])" }
    $d = "Suzuki $a ex-showroom price in Hyderabad$(if ($lead -like 'from*') { ' ' })$lead. $spec. Get the on-road price and book a test ride at Aarush Suzuki."
    if ($d.Length -gt 155) { $d = "Suzuki $a ex-showroom price in Hyderabad$(if ($lead -like 'from*') { ' ' })$lead. $spec. Get the on-road price and book a test ride." }
    return $d
  }
  $d = "Suzuki $a in Hyderabad: $($v.summary.TrimEnd('.')). $spec. Check availability and get the on-road price at Aarush Suzuki."
  if ($d.Length -gt 155) { $d = "Suzuki $a in Hyderabad: $($v.summary.TrimEnd('.')). Specs, colours, availability and the on-road price." }
  return $d
}

# Model-page FAQs, built only from the page's own data (price table, colours, highlights).
function Model-Faqs($v) {
  $a = AliasOf $v; $n = $v.name; $f = @()
  $branches = @($showrooms).Count
  if ($v.prices -and $v.prices.Count) {
    $nums = PriceNums $v; $lo = Rupees (($nums | Measure-Object -Minimum).Minimum); $hi = Rupees (($nums | Measure-Object -Maximum).Maximum)
    $pd = PriceDate $v; $when = if ($pd) { " as published by Suzuki Motorcycle India on $pd" } else { '' }
    $variants = ($v.prices | ForEach-Object { "$($_[0]) $($_[1])" }) -join '; '
    $ans = if ($nums.Count -gt 1) { "The Suzuki $a costs $lo to $hi ex-showroom in Hyderabad across $($nums.Count) variants$($when): $variants." } else { "The Suzuki $a costs $lo ex-showroom in Hyderabad$($when)." }
    $f += , @("What is the ex-showroom price of the Suzuki $a in Hyderabad?", $ans, '#price', 'See the price table')
    $f += , @("What is the on-road price of the Suzuki $a in Hyderabad?", "The on-road price is the ex-showroom price (from $lo) plus registration (RTO), insurance and any accessories you choose, so it depends on the variant and options. Aarush Suzuki sales will give you an exact quote: call 88852 46633 or ask on WhatsApp.", "/contact/?model=$($v.id)&topic=price#enquire", 'Get the on-road price')
  } else {
    $f += , @("Is the Suzuki $n available at Aarush Suzuki?", "Ask your nearest Aarush Suzuki showroom about availability, bookings and the on-road price of the Suzuki $n. Call 88852 46633 or send an enquiry and our team will call you back.", "/contact/?model=$($v.id)&topic=availability#enquire", 'Ask about availability')
  }
  $cols = @($v.colours | ForEach-Object { $_[0] })
  if ($cols.Count) { $f += , @("How many colours does the Suzuki $a come in?", "Suzuki lists the $n in $($cols.Count) colours: $($cols -join '; '). Ask us which colours are in stock.", '#colours', 'See the colours') }
  if ($v.category -eq 'electric') {
    $f += , @("What is the range of the Suzuki $n?", "The $n has a certified range of $(HL $v 'Range (AIS 040)') as per AIS 040, from a $(HL $v 'Battery') lithium iron phosphate (LFP) battery. A fast charger takes it from 0 to 80% in 1 h 12 min.", '#specifications', 'Full specifications')
  } else {
    $bits = @(); foreach ($k in 'Displacement', 'Max power', 'Max torque', 'Gearbox', 'Kerb weight', 'Seat height') { $x = HL $v $k; if ($x) { $bits += "$($k.ToLower()) $x" } }
    $f += , @("What are the key specifications of the Suzuki $a?", "The Suzuki $n has $(($bits | Select-Object -First 4) -join ', '), as published by Suzuki Motorcycle India.", '#specifications', 'Full specifications')
  }
  $f += , @("Where can I test ride the Suzuki $a in Hyderabad?", "Book a test ride online, or visit any of Aarush Suzuki's $branches showrooms in Hyderabad and Telangana. Bring a valid driving licence; our team will call to confirm a time.", "/book-a-test-ride/?model=$($v.id)", 'Book a test ride')
  return , $f
}
function Faq-Section($faqs, $title, $lead, $id) {
  $k = 0
  $items = foreach ($q in $faqs) {
    $k++
    $more = if ($q[2]) { " <a class=`"faq__link`" href=`"$(Enc $q[2])`">$(Enc $q[3])</a>" } else { '' }
@"
<details class="faq__item" name="$id"$(if ($k -eq 1) { ' open' })>
            <summary><span class="faq__num">$('{0:D2}' -f $k)</span><h3 class="faq__q">$(Enc $q[0])</h3><i class="faq__icon" aria-hidden="true"></i></summary>
            <div class="faq__a"><p>$(Enc $q[1])$more</p></div>
          </details>
"@
  }
@"
    <section class="faq faq--page" id="$id" aria-labelledby="$id-title">
      <div class="faq__inner">
        <header class="faq__head">
          <p class="faq__kicker">FAQs</p>
          <h2 class="faq__title" id="$id-title">$(Enc $title)</h2>
          <p class="faq__lead">$(Enc $lead)</p>
          <a class="link-arrow" href="https://wa.me/$($site.contact.whatsapp)" target="_blank" rel="noopener">Ask us on WhatsApp</a>
        </header>
        <div class="faq__list">
          $($items -join "`n          ")
        </div>
      </div>
    </section>
"@
}
function Faq-JsonLd($faqs) {
  $qa = ($faqs | ForEach-Object { "{`"@type`":`"Question`",`"name`":$(JsonStr $_[0]),`"acceptedAnswer`":{`"@type`":`"Answer`",`"text`":$(JsonStr $_[1])}}" }) -join ','
  "{`"@context`":`"https://schema.org`",`"@type`":`"FAQPage`",`"mainEntity`":[$qa]}"
}
function Offers-Json($v) {
  if (-not $v.prices -or -not $v.prices.Count) { return '' }
  $nums = PriceNums $v
  $seller = "`"seller`":{`"@id`":`"$BASE/#org`"}"
  if ($nums.Count -gt 1) {
    return ",`"offers`":{`"@type`":`"AggregateOffer`",`"priceCurrency`":`"INR`",`"lowPrice`":$(($nums | Measure-Object -Minimum).Minimum),`"highPrice`":$(($nums | Measure-Object -Maximum).Maximum),`"offerCount`":$($nums.Count),`"url`":$(JsonStr "$BASE$($v.url)#price"),$seller}"
  }
  return ",`"offers`":{`"@type`":`"Offer`",`"priceCurrency`":`"INR`",`"price`":$($nums[0]),`"url`":$(JsonStr "$BASE$($v.url)#price"),$seller}"
}
function ItemList-JsonLd($cg) {
  $i = 0
  $items = foreach ($v in @($vehicles | Where-Object { $_.category -eq $cg -and $_.published -ne $false })) { $i++; "{`"@type`":`"ListItem`",`"position`":$i,`"name`":$(JsonStr "Suzuki $($v.name)"),`"url`":$(JsonStr "$BASE$($v.url)")}" }
  "{`"@context`":`"https://schema.org`",`"@type`":`"ItemList`",`"name`":$(JsonStr "Suzuki $($CAT[$cg].plural) at Aarush Suzuki"),`"itemListElement`":[" + ($items -join ',') + "]}"
}

# Homepage blocks that used to exist only after JavaScript ran (crawlers and AI bots now see them).
$CATLABEL = @{ motorcycles = 'Motorcycle'; scooters = 'Scooter'; electric = 'Electric' }
function Render-Lineup {
  (@($vehicles | Where-Object { $_.category -ne 'premium' -and $site.featured -contains $_.id }) | ForEach-Object {
    $v = $_; $pf = PriceFrom $v
    $price = if ($pf) { "<span class=`"slide__price`">Ex-showroom Hyderabad from <b>$pf</b></span>" } else { '' }
@"
<article class="slide">
        <div class="slide__scene">
          <span class="slide__word" aria-hidden="true">$(Enc ($v.name.Split(' ')[0]))</span>
          <a class="slide__vehicle" href="$($v.url)" tabindex="-1" aria-hidden="true">
            <img src="$($v.image.Replace('/img/models/', '/img/models/trim/'))" alt="" loading="lazy">
          </a>
          <span class="slide__shadow" aria-hidden="true"></span>
        </div>
        <div class="slide__info">
          <span class="slide__cat">$($CATLABEL[$v.category])</span>
          <h3 class="slide__name"><a href="$($v.url)">$(Enc $v.name)</a></h3>
          <p class="slide__line">$(Enc $v.summary)$price</p>
          <div class="slide__actions">
            <a class="link-arrow" href="$($v.url)">Explore <span class="sr-only">the Suzuki $(Enc $v.name) </span>model</a>
            <a class="slide__enquire" href="/contact/?model=$($v.id)&amp;topic=price#enquire">Enquire now<span class="sr-only"> about the $(Enc $v.name)</span></a>
          </div>
        </div>
      </article>
"@ }) -join ''
}
function Render-PremiumCards {
  (@($vehicles | Where-Object { $_.category -eq 'premium' }) | ForEach-Object {
@"
<a class="bike" href="$($_.url)">
        <img src="$($_.image)" alt="$(Enc "Suzuki $($_.name) on the road")" width="550" height="640" loading="lazy">
        <span class="bike__body">
          <span><h3>$(Enc $_.name)</h3><p>$(Enc $_.summary)</p></span>
          <span class="bike__go" aria-hidden="true"></span>
        </span>
      </a>
"@ }) -join ''
}
function Render-HomeDirectory($region) {
  (@($showrooms | Where-Object { $_.region -eq $region }) | ForEach-Object {
    $s = $_
    $tag = if ($s.id -like 'best-value*') { 'Suzuki Best Value · Sales &amp; service' } else { 'Sales &amp; service' }
    $svc = if ($s.serviceAddress) { "<small>Service centre: $(Enc $s.serviceAddress)</small>" } else { '' }
@"
<li class="dir-row">
          <div><h3>$(Enc $s.name)</h3><span class="dir-row__tag">$tag</span></div>
          <address>$(Enc $s.address)$svc</address>
          <div class="dir-row__phones">
            <a href="tel:+91$($s.sales)"><span>Sales</span>$(Phone $s.sales)</a>
            <a href="tel:+91$($s.service)"><span>Service</span>$(Phone $s.service)</a>
          </div>
          <a class="link-arrow dir-row__map" href="$(DirUrl $s.name $s.address)" target="_blank" rel="noopener" aria-label="Directions to Aarush Suzuki $(Enc $s.name) on Google Maps">Directions</a>
        </li>
"@ }) -join ''
}

# Analytics / verification tags from site.json → "analytics" (empty = nothing is added).
function Analytics-Head {
  $a = $site.analytics; if (-not $a) { return '' }
  $out = ''
  if ($a.googleVerification) { $out += "  <meta name=`"google-site-verification`" content=`"$(Enc $a.googleVerification)`">`n" }
  if ($a.bingVerification) { $out += "  <meta name=`"msvalidate.01`" content=`"$(Enc $a.bingVerification)`">`n" }
  if ($a.ga4) {
    $out += "  <script async src=`"https://www.googletagmanager.com/gtag/js?id=$($a.ga4)`"></script>`n"
    $out += "  <script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','$($a.ga4)');</script>`n"
  }
  return $out
}

function Render-Token($name, $arg) {
  switch ($name) {
    'LINEUP' { return Render-Lineup }
    'CATFROM' { $nums = @($vehicles | Where-Object { $_.category -eq $arg -and $_.prices } | ForEach-Object { PriceNums $_ }); return Rupees (($nums | Measure-Object -Minimum).Minimum) }
    'PREMIUM_CARDS' { return Render-PremiumCards }
    'HOME_DIRECTORY' { return Render-HomeDirectory $arg }
    'MODEL_ROWS' {
      $groups = [ordered]@{}
      foreach ($part in $arg.Split(';')) { $kv = $part.Split('='); $groups[$kv[0]] = $kv[1].Split(',') }
      return Render-ModelRows '' $groups
    }
    'COMPARE' {
      $ids = $arg.Split(',')
      $rows = @(@('Engine', '^Displacement'), @('Max power', 'Max(imum)?\s*(Engine\s*)?(Power|Output)|^Engine Output'), @('Max torque', 'Max(imum)? Torque|^Torque'),
        @('Gearbox', '^Transmission'), @('Kerb weight', 'Kerb|Curb'), @('Seat height', 'Seat Height'), @('Ground clearance', 'Ground Clearance'), @('Fuel tank', 'Fuel Tank Capacity'), @('Front brake', 'Brake>^Front$'))
      return Render-Compare $ids $rows
    }
    'SPEC' { $p = $arg.Split('|'); return Enc (Get-Spec $VM[$p[0]] $p[1]) }
    'STAGE' { return Stage $VM[$arg] 'pstage--hero' }
    'STATS' { return Stats $VM[$arg] '' }
    'FEATURES' { $p = $arg.Split('|'); return Render-Features $VM[$p[0]] ([int]$p[1]) '' }
    'DIRECTORY' { return Render-Directory $arg $false }
    'FORM' { $p = $arg.Split('|'); return Render-RideForm $p[1] $p[2] $p[0] $(if ($p.Count -gt 3) { $p[3] } else { '' }) }
    'SOCIAL' {
      # Facebook / Instagram / YouTube icons from site.json (an empty URL hides that icon)
      $ico = @{
        facebook  = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path fill="currentColor" d="M24 12.07C24 5.41 18.63 0 12 0S0 5.4 0 12.07C0 18.1 4.39 23.1 10.13 24v-8.44H7.08v-3.49h3.04V9.41c0-3.02 1.8-4.7 4.54-4.7 1.31 0 2.68.24 2.68.24v2.97h-1.5c-1.5 0-1.96.93-1.96 1.89v2.26h3.32l-.53 3.5h-2.8V24C19.62 23.1 24 18.1 24 12.07"/></svg>'
        instagram = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.9"><rect x="3" y="3" width="18" height="18" rx="5.2"/><circle cx="12" cy="12" r="4.1"/><circle cx="17.4" cy="6.6" r="1.15" fill="currentColor" stroke="none"/></svg>'
        youtube   = '<svg viewBox="0 0 24 24" width="19" height="19" aria-hidden="true"><path fill="currentColor" d="M23.5 6.2a3 3 0 0 0-2.1-2.1C19.5 3.6 12 3.6 12 3.6s-7.5 0-9.4.5A3 3 0 0 0 .5 6.2 31 31 0 0 0 0 12a31 31 0 0 0 .5 5.8 3 3 0 0 0 2.1 2.1c1.9.5 9.4.5 9.4.5s7.5 0 9.4-.5a3 3 0 0 0 2.1-2.1A31 31 0 0 0 24 12a31 31 0 0 0-.5-5.8ZM9.6 15.6V8.4l6.2 3.6-6.2 3.6Z"/></svg>'
      }
      $names = [ordered]@{ facebook = 'Facebook'; instagram = 'Instagram'; youtube = 'YouTube' }
      $items = foreach ($k in $names.Keys) {
        $url = $site.contact.$k
        if ($url) { "<a href=`"$url`" target=`"_blank`" rel=`"noopener`" aria-label=`"Aarush Suzuki on $($names[$k])`" title=`"$($names[$k])`">$($ico[$k])</a>" }
      }
      return "<nav class=`"social $arg`" aria-label=`"Social media`">" + ($items -join '') + "</nav>"
    }
    'HERO_SLIDES' {
      $todayIso = Get-Date -Format 'yyyy-MM-dd'
      $slides = @($site.heroSlides | Where-Object { -not $_.until -or $_.until -ge $todayIso }); $n = $slides.Count; $i = 0
      $html = foreach ($s in $slides) {
        $v = $VM[$s.model]; $i++
        $load = if ($i -eq 1) { 'eager" fetchpriority="high' } else { 'lazy' }
        $active = if ($i -eq 1) { ' is-active' } else { '' }
        $note = if ($s.note) { " data-note=`"$(Enc $s.note)`"" } else { '' }
        if ($s.until) { $note += " data-until=`"$($s.until)`"" }
@"
<div class="hs__slide$active" data-slide data-label="$(Enc $s.label)" data-url="$($v.url)" data-ride="/book-a-test-ride/?model=$($v.id)"$note role="group" aria-roledescription="slide" aria-label="$($i) of $($n): Suzuki $(Enc $s.label)">
            <picture class="hs__amb" aria-hidden="true">
              <source media="(max-width: 767px)" srcset="/assets/img/banners/$($s.model)-mobile.jpg">
              <img src="/assets/img/banners/$($s.model)-desktop.jpg" alt="" width="1920" height="700" loading="$(if ($i -eq 1) { 'eager' } else { 'lazy' })">
            </picture>
            <a class="hs__media" href="$($v.url)" tabindex="-1" aria-hidden="true">
              <picture>
                <source media="(max-width: 767px)" srcset="/assets/img/banners/$($s.model)-mobile.jpg">
                <img src="/assets/img/banners/$($s.model)-desktop.jpg" alt="Suzuki $(Enc $s.label) official banner" width="1920" height="700" loading="$load">
              </picture>
            </a>
          </div>
"@
      }
      $first = $slides[0]; $fv = $VM[$first.model]
      $dots = (1..$n | ForEach-Object { $sel = if ($_ -eq 1) { 'true' } else { 'false' }; "<button type=`"button`" class=`"hs__dot`" data-goto=`"$($_ - 1)`" aria-label=`"Show slide $_`" aria-current=`"$sel`"><i></i></button>" }) -join ''
@"
<section class="hs" aria-roledescription="carousel" aria-label="Featured Suzuki models" data-hs>
        <div class="hs__track" aria-live="off">
          $($html -join "`n          ")
        </div>
        <div class="hs__bar">
          <div class="hs__info">
            <strong class="hs__label" data-hs-label>$(Enc $first.label)</strong>
            <small class="hs__note" data-hs-note>$(Enc $first.note)</small>
          </div>
          <div class="hs__ctas">
            <a class="btn btn--ink" data-hs-explore href="$($fv.url)">Explore $(Enc $first.label)</a>
            <a class="btn btn--outline" data-hs-ride href="/book-a-test-ride/?model=$($fv.id)">Book a test ride</a>
          </div>
          <div class="hs__controls">
            <div class="hs__dots" role="group" aria-label="Choose slide">$dots</div>
          </div>
        </div>
      </section>
"@
    }
    'REELS' {
      # Video-only reel grid: no handle, profile, counts or follow links. A reel with a local MP4
      # (site.json → reels[].video) autoplays muted while visible; otherwise Instagram's embed is
      # shown cropped to just the video (it plays on tap — Instagram does not allow autoplay).
      $cards = foreach ($r in $site.reels) {
        $frame = if ($r.video) {
          $poster = if ($r.poster) { " poster=`"$($r.poster)`"" } else { '' }
          "<video class=`"reel__video`" src=`"$($r.video)`"$poster muted loop playsinline disablepictureinpicture disableremoteplayback preload=`"none`" data-reel-video aria-label=`"Aarush Suzuki reel`"></video>"
        } else {
          "<div class=`"reel__embed`" data-reel-embed=`"https://www.instagram.com/reel/$($r.code)/embed/`"></div>"
        }
@"
<li class="reel" data-reel>
            <div class="reel__frame">$frame</div>
          </li>
"@
      }
@"
<section class="reels" aria-labelledby="reels-title">
      <div class="wrap reels__head">
        <h2 class="sec-title" id="reels-title">From our Instagram</h2>
      </div>
      <ul class="reels__row" aria-label="Reels">
          $($cards -join "`n          ")
      </ul>
    </section>
"@
    }
    'REVIEWS' {
      # Genuine Google reviews (src/data/reviews.json), shown one at a time as a large quote.
      $rv = Read-Text "$src/data/reviews.json" | ConvertFrom-Json
      $n = @($rv.items).Count; $k = 0
      $star = '<svg viewBox="0 0 20 20" aria-hidden="true"><path d="M10 1.6l2.6 5.3 5.8.8-4.2 4.1 1 5.8L10 14.9l-5.2 2.7 1-5.8L1.6 7.7l5.8-.8z"/></svg>'
      $quotes = foreach ($r in $rv.items) {
        $sub = Enc $r.type; if ($r.branch) { $sub += " &middot; $(Enc $r.branch)" }
        $stars = ($star * [int]$r.rating)
        $cls = if ($k -eq 0) { 'rv__quote is-active' } else { 'rv__quote' }
        $k++
@"
<figure class="$cls" data-rv-item aria-roledescription="slide" aria-label="Review $k of $n">
            <p class="rv__stars" role="img" aria-label="Rated $($r.rating) out of 5">$stars</p>
            <blockquote><p>$(Enc $r.text)</p></blockquote>
            <figcaption><strong>$(Enc $r.name)</strong><span>$sub &middot; Google review</span></figcaption>
          </figure>
"@
      }
      $dots = (1..$n | ForEach-Object { "<button type=`"button`" class=`"hs__dot`" data-rv-goto=`"$($_ - 1)`" aria-label=`"Show review $_`" aria-current=`"$(if ($_ -eq 1) {'true'} else {'false'})`"><i></i></button>" }) -join ''
@"
<section class="rv" id="reviews" aria-labelledby="rv-title">
      <div class="rv__inner">
        <header class="rv__head">
          <p class="rv__kicker"><span class="rv__g" aria-hidden="true">G</span>Google reviews</p>
          <h2 class="rv__title" id="rv-title">In our riders&rsquo; words.</h2>
          <p class="rv__lead">What customers say about buying, collecting and servicing their Suzuki at Aarush Suzuki.</p>
          <a class="btn btn--outline rv__more" href="$(Enc $rv.moreUrl)" target="_blank" rel="noopener">Read more reviews on Google</a>
        </header>
        <div class="rv__stage" data-reviews aria-roledescription="carousel" aria-label="Customer reviews">
          <span class="rv__mark" aria-hidden="true">&ldquo;</span>
          <div class="rv__quotes" aria-live="polite">
          $($quotes -join "`n          ")
          </div>
          <div class="rv__bar">
            <p class="rv__count" aria-hidden="true"><b data-rv-now>01</b> / $('{0:D2}' -f $n)</p>
            <div class="rv__dots" role="group" aria-label="Choose review">$dots</div>
            <div class="rv__arrows">
              <button type="button" class="rv__arrow" data-rv-prev aria-label="Previous review"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg></button>
              <button type="button" class="rv__arrow" data-rv-next aria-label="Next review"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5l7 7-7 7"/></svg></button>
            </div>
          </div>
        </div>
      </div>
    </section>
"@
    }
    'FAQ' {
      # Accordion from src/data/faqs.json (FAQPage JSON-LD is added on the home page from the same file).
      $faqs = Read-Text "$src/data/faqs.json" | ConvertFrom-Json
      $k = 0
      $items = foreach ($f in $faqs) {
        $k++
        $more = if ($f.link) { " <a class=`"faq__link`" href=`"$($f.link[0])`">$(Enc $f.link[1])</a>" } else { '' }
@"
<details class="faq__item" name="faq"$(if ($k -eq 1) { ' open' })>
            <summary><span class="faq__num">$('{0:D2}' -f $k)</span><span class="faq__q">$(Enc $f.q)</span><i class="faq__icon" aria-hidden="true"></i></summary>
            <div class="faq__a"><p>$(Enc $f.a)$more</p></div>
          </details>
"@
      }
@"
<section class="faq" aria-labelledby="faq-title">
      <div class="faq__inner">
        <header class="faq__head">
          <p class="faq__kicker">FAQs</p>
          <h2 class="faq__title" id="faq-title">Questions, answered.</h2>
          <p class="faq__lead">Test rides, bookings, servicing and our showrooms, in brief. Anything else, just ask.</p>
          <dl class="faq__lines">
            <div><dt>Sales</dt><dd><a href="tel:+918885246633">88852 46633</a></dd></div>
            <div><dt>Service</dt><dd><a href="tel:+918885106633">88851 06633</a></dd></div>
          </dl>
          <a class="link-arrow" href="https://wa.me/918885246633" target="_blank" rel="noopener">Ask us on WhatsApp</a>
        </header>
        <div class="faq__list">
          $($items -join "`n          ")
        </div>
      </div>
    </section>
"@
    }
    'SHOWROOM_PHOTOS' {
      # Add real showroom photos to site.json "showroomPhotos": [["/assets/img/showrooms/attapur.jpg", "Caption"], ...]
      if (-not $site.showroomPhotos -or $site.showroomPhotos.Count -eq 0) { return '' }
      $figs = ($site.showroomPhotos | ForEach-Object { "<figure><img src=`"$($_[0])`" alt=`"$(Enc $_[1])`" loading=`"lazy`"><figcaption>$(Enc $_[1])</figcaption></figure>" }) -join ''
      return "`n    <section class=`"ab-photos`" aria-label=`"Our showrooms`"><div class=`"ab-photos__row`">$figs</div></section>`n"
    }
    'SELECTOR' { return Render-Selector $arg.Split(',') }
    'FEATURE_LIST' {
      # id|n -> plain feature list (title + text) for dark sections
      $p = $arg.Split('|')
      return (@($VM[$p[0]].features | Select-Object -First ([int]$p[1])) | ForEach-Object { "<li><strong>$(Enc $_[0])</strong><span>$(Enc (Clip $_[1]))</span></li>" }) -join "`n"
    }
    'PREMIUM_PANELS' {
      $n = 0
      return (@('hayabusa', 'gsx-8r', 'v-strom-800de') | ForEach-Object {
        $v = $VM[$_]; $n++
        $flip = if ($n % 2 -eq 0) { ' pbike--flip' } else { '' }
        $feats = (@($v.features | Select-Object -First 3) | ForEach-Object { "<li>$(Enc $_[0])</li>" }) -join ''
        $featBlock = if ($feats) { "<ul class=`"ticks ticks--light`">$feats</ul>" } else { '' }
        $wa = WA "Hi Aarush Suzuki, I'd like to know about availability of the Suzuki $($v.name)."
@"
<article class="pbike$flip" id="$($v.id)">
          <figure class="pbike__photo" data-parallax-img><img src="$($v.image)" alt="$(Enc "Suzuki $($v.name) on the road")" loading="lazy" width="550" height="640"></figure>
          <div class="pbike__body">
            <h2 class="pbike__name">$(Enc $v.name)</h2>
            <p class="pbike__tag">$(Enc $v.tagline)</p>
            <p class="pbike__text">$(Enc $v.overview)</p>
            $(Stats $v 'stats--dark')
            $featBlock
            <div class="pbike__actions">
              <a class="btn btn--light" href="$($v.url)">Explore $(Enc $v.name)</a>
              <a class="link-arrow link-arrow--light" href="/contact/?model=$($v.id)&amp;topic=availability#enquire">Enquire now</a>
            </div>
          </div>
        </article>
"@
      }) -join "`n"
    }
    'WA' { return WA $arg }
    'YEAR' { return (Get-Date).Year }
    default { throw "Unknown token {{$name}}" }
  }
}

function Expand-Tokens($body) {
  [regex]::Replace($body, '\{\{([A-Z_]+)(?::([^}]*))?\}\}', [Text.RegularExpressions.MatchEvaluator] { param($m) Render-Token $m.Groups[1].Value $m.Groups[2].Value })
}

# ------------------------------------------------------- vehicle pages ----
function Render-Vehicle($v) {
  $c = $CAT[$v.category]
  $photo = Is-Photo $v
  $colours = ($v.colours | ForEach-Object -Begin { $i = 0 } -Process {
    $hex = if ($_[1]) { $_[1] } else { '#888' }
    $sel = if ($i -eq 0) { 'true' } else { 'false' }; $i++
    $cimg = if ($_[2]) { $_[2] } else { $v.image }
    "<li><button type=`"button`" class=`"swatch`" aria-pressed=`"$sel`" data-colour=`"$(Enc $_[0])`" data-colour-img=`"$cimg`" style=`"--sw:$hex`"><span class=`"sr`">$(Enc $_[0])</span></button></li>"
  }) -join ''
  $firstColour = if ($v.colours.Count) { $v.colours[0][0] } else { '' }
  $firstColourImg = if ($v.colours.Count -and $v.colours[0][2]) { $v.colours[0][2] } else { $v.image }
  $sharedNote = if ($v.coloursShared) { "<p class=`"v-colours__note`">Suzuki lists one colour range for both versions of this model. Ask us which colours are in stock for the $(Enc $v.name).</p>" } else { '' }

  $specGroups = ($v.specs | ForEach-Object -Begin { $i = 0 } -Process {
    $open = if ($i -lt 1) { ' open' } else { '' }; $i++
    $rows = ($_[1] | ForEach-Object { "<tr><th scope=`"row`">$(Enc $_[0])</th><td>$(Enc $_[1])</td></tr>" }) -join ''
    "<details class=`"specs__group`"$open><summary>$(Enc $_[0])<i aria-hidden=`"true`"></i></summary><table>$rows</table></details>"
  }) -join "`n"

  $gallery = ''
  if ($v.gallery.Count) {
    $imgs = ($v.gallery | ForEach-Object -Begin { $i = 0 } -Process { $i++; "<button type=`"button`" class=`"gallery__item`" data-lightbox-src=`"$_`" aria-label=`"Open $(Enc $v.name) photo $i`"><img src=`"$_`" alt=`"$(Enc "Suzuki $($v.name) – photo $i")`" loading=`"lazy`"></button>" }) -join ''
    $gallery = @"

    <section class="v-gallery" aria-labelledby="g-title">
      <div class="wrap v-gallery__head"><h2 id="g-title" class="sec-title">Gallery</h2><p>Official Suzuki photography.</p></div>
      <div class="gallery" tabindex="0">$imgs</div>
    </section>
"@
  }

  # Official Hyderabad ex-showroom prices (from Suzuki Motorcycle India)
  $priceSec = ''
  if ($v.prices -and $v.prices.Count) {
    $rows = ($v.prices | ForEach-Object { "<tr><th scope=`"row`">$(Enc $_[0])</th><td>$(Enc $_[1])</td></tr>" }) -join ''
    $priceSec = @"

    <section class="v-price" id="price" aria-labelledby="p-title">
      <div class="wrap v-price__grid">
        <div>
          <h2 id="p-title" class="sec-title">Price in Hyderabad</h2>
          <p class="v-price__note">$(Enc $v.pricesNote) On-road price adds registration, insurance and any accessories you choose.</p>
          <a class="btn btn--ink" href="/contact/?model=$($v.id)&amp;topic=price#enquire">Get the on-road price</a>
        </div>
        <table class="v-price__table"><thead><tr><th scope="col">Variant</th><th scope="col">Ex-showroom</th></tr></thead><tbody>$rows</tbody></table>
      </div>
    </section>
"@
  }

  # Genuine accessories (official names and photos)
  $accSec = ''
  if ($v.accessories -and $v.accessories.Count) {
    $items = ($v.accessories | ForEach-Object { "<li class=`"acc`"><img src=`"$($_[1])`" alt=`"$(Enc "$($_[0]) for Suzuki $($v.name)")`" loading=`"lazy`" width=`"520`" height=`"420`"><span>$(Enc $_[0])</span></li>" }) -join ''
    $accSec = @"

    <section class="v-acc" id="accessories" aria-labelledby="a-title">
      <div class="wrap v-acc__head"><h2 id="a-title" class="sec-title">Genuine accessories</h2><p>Supplied and fitted at any Aarush Suzuki showroom. <a class="link-arrow" href="/contact/?model=$($v.id)&amp;topic=accessories#enquire">Ask about accessories</a></p></div>
      <ul class="accs" tabindex="0" aria-label="Accessories">$items</ul>
    </section>
"@
  }

  # Official brochure downloads
  $brochures = ''
  if ($v.brochures -and $v.brochures.Count) {
    $brochures = ($v.brochures | ForEach-Object { "<a class=`"link-arrow`" href=`"$($_[1])`" target=`"_blank`" rel=`"noopener`">Download $(Enc $_[0]) brochure (PDF)</a>" }) -join ''
  }

  $features = ''
  if ($v.features.Count) {
    $features = @"

    <section class="v-features" id="features" aria-labelledby="f-title">
      <div class="wrap">
        <h2 id="f-title" class="sec-title">What sets it apart</h2>
        <div class="feats">$(Render-Features $v 8 '')</div>
      </div>
    </section>
"@
  }

  $similar = ($v.similar | ForEach-Object {
    $s = $VM[$_]
    $media = if (Is-Photo $s) { "<img src=`"$($s.image)`" alt=`"`" loading=`"lazy`" class=`"sim__photo`">" } else { "<img src=`"$($s.image)`" alt=`"`" loading=`"lazy`">" }
    "<a class=`"sim`" href=`"$($s.url)`"><span class=`"sim__media`">$media</span><span class=`"sim__cat`">$($CAT[$s.category].label)</span><strong>$(Enc $s.name)</strong><span>$(Enc $s.summary)</span></a>"
  }) -join ''

  $faqs = Model-Faqs $v
  $enqForm = "/contact/?model=$($v.id)&amp;topic=price#enquire"
  $enqWA = WA "Hi Aarush Suzuki, I'm interested in the Suzuki $($v.name). Please share colours in stock and the on-road price."
  $heroCls = if ($photo) { 'v-hero v-hero--photo' } else { 'v-hero' }

  $body = @"
<main id="main" class="vpage vpage--$($v.category)">
    <section class="$heroCls" aria-labelledby="v-name">
      <div class="v-hero__grid">
        <div class="v-hero__text">
          $(Crumbs @(@('Home', '/'), @($c.plural, $c.url), @($v.name, $v.url)))
          <p class="v-hero__tag">$(Enc $v.tagline)</p>
          <h1 class="v-hero__name" id="v-name">Suzuki <span>$(Enc $v.name)</span> <small class="h1-sub">$(if ($v.prices -and $v.prices.Count) { 'Price in Hyderabad' } else { 'in Hyderabad' })</small></h1>
          <p class="v-hero__summary">$(Enc $v.summary)</p>
          $(PriceLine $v 'price-from--hero')
          <div class="v-hero__actions">
            <a class="btn btn--ink" href="/book-a-test-ride/?model=$($v.id)">Book a test ride</a>
            <a class="btn btn--outline" href="$enqForm">Enquire now</a>
          </div>
        </div>
        <div class="v-hero__visual">$(Stage $v 'pstage--hero')</div>
      </div>
      $(Stats $v 'stats--hero')
    </section>

    <section class="v-overview" aria-labelledby="o-title">
      <div class="wrap v-overview__grid">
        <p id="o-title" class="v-overview__lead">$(Enc $v.overview)</p>
        <nav class="v-jump" aria-label="On this page">
          $(if ($priceSec) { '<a href="#price">Price</a>' })<a href="#colours">Colours</a>$(if ($v.features.Count) { '<a href="#features">Features</a>' })$(if ($accSec) { '<a href="#accessories">Accessories</a>' })<a href="#specifications">Specifications</a><a href="#faq">FAQs</a><a href="#enquire">Enquire</a>
        </nav>
      </div>
    </section>

$priceSec
    <section class="v-colours" id="colours" aria-labelledby="c-title">
      <div class="wrap v-colours__grid">
        <div>
          <h2 id="c-title" class="sec-title">Colours</h2>
          <p class="v-colours__name" data-colour-name aria-live="polite">$(Enc $firstColour)</p>
          $sharedNote
          <ul class="swatches" data-swatches>$colours</ul>
        </div>
        <figure class="v-colours__visual$(if ($photo) { ' v-colours__visual--photo' })"><img src="$firstColourImg" alt="$(Enc "Suzuki $($v.name) in $firstColour")" data-colour-visual loading="lazy"></figure>
      </div>
    </section>
$features
$accSec
    <section class="v-specs" id="specifications" aria-labelledby="s-title">
      <div class="wrap v-specs__grid">
        <div class="v-specs__intro">
          <h2 id="s-title" class="sec-title">Specifications</h2>
          <p>Technical data as published by Suzuki Motorcycle India. Specifications can change without notice; our team will confirm details for the variant you choose.</p>
          $brochures
          <a class="link-arrow" href="$($v.official)" target="_blank" rel="noopener">$(if ($v.id -eq 'gixxer') { 'Official Gixxer range page (Gixxer SF)' } elseif ($v.id -eq 'gixxer-250') { 'Official Gixxer 250 range page (Gixxer SF 250)' } else { "Official $(Enc $v.name) page" })</a>
        </div>
        <div class="specs">$specGroups</div>
      </div>
    </section>
$gallery
$(Faq-Section $faqs "Suzuki $(AliasOf $v) questions" "Price, colours, specifications and test rides for the $($v.name) at Aarush Suzuki, answered from the details on this page." 'faq')
    <section class="v-enquire" id="enquire" aria-labelledby="e-title">
      <div class="wrap v-enquire__grid">
        <div>
          <h2 id="e-title" class="v-enquire__title">Ride the $(Enc $v.name).</h2>
          <p>Visit any of our 12 showrooms, or tell us when suits you and we’ll have one ready.</p>
        </div>
        <ul class="v-enquire__opts">
          <li><a href="/book-a-test-ride/?model=$($v.id)"><strong>Book a test ride</strong><span>Pick a showroom and a date</span></a></li>
          <li><a href="$enqForm"><strong>Enquire now</strong><span>On-road price, colours and stock</span></a></li>
          <li><a href="$enqWA" target="_blank" rel="noopener"><strong>WhatsApp</strong><span>Chat with our sales team</span></a></li>
          <li><a href="tel:+91$($site.contact.sales)"><strong>Call sales</strong><span>$(Phone $site.contact.sales)</span></a></li>
        </ul>
      </div>
    </section>

    <section class="v-similar" aria-labelledby="sim-title">
      <div class="wrap">
        <h2 id="sim-title" class="sec-title">You might also like</h2>
        <div class="sims">$similar</div>
      </div>
    </section>
  </main>
"@

  $img = if ($v.image -like 'http*') { $v.image } else { $BASE + $v.image }
  $colourList = (@($v.colours | ForEach-Object { JsonStr $_[0] }) -join ',')
  $product = "{`"@context`":`"https://schema.org`",`"@type`":`"Product`",`"@id`":$(JsonStr "$BASE$($v.url)#product"),`"name`":$(JsonStr "Suzuki $($v.name)"),`"alternateName`":$(JsonStr "Suzuki $(AliasOf $v)"),`"brand`":{`"@type`":`"Brand`",`"name`":`"Suzuki`"},`"category`":$(JsonStr $c.label),`"description`":$(JsonStr $v.overview),`"image`":$(JsonStr $img),`"color`":[$colourList],`"url`":$(JsonStr ($BASE + $v.url))$(Offers-Json $v)}"
  $crumb = Breadcrumb-JsonLd @(@('Home', '/'), @($c.plural, $c.url), @($v.name, $v.url))
  $meta = @{
    title = Model-Title $v
    description = Model-Description $v
    path = $v.url; bodyClass = "page-vehicle page-vehicle--$($v.category)"; ogImage = $v.image; ogType = 'product'; ogAlt = Alt $v
    jsonld = (Script-Ld $product) + (Script-Ld $crumb) + (Script-Ld (Faq-JsonLd $faqs))
  }
  if (-not $photo) { $meta.preload = $v.image }
  return Assemble $meta $body
}

# --------------------------------------------------------------- pages ----
$pages = @()
Get-ChildItem "$src/pages" -Filter *.html | ForEach-Object {
  $raw = Read-Text $_.FullName
  $m = [regex]::Match($raw, '^\s*<!--(.*?)-->', 'Singleline')
  if (-not $m.Success) { throw "Missing meta block in $($_.Name)" }
  $meta = @{}
  foreach ($line in $m.Groups[1].Value -split "`r?`n") {
    if ($line -match '^\s*([A-Za-z]+)\s*:\s*(.+?)\s*$') { $meta[$Matches[1]] = $Matches[2] }
  }
  $body = Expand-Tokens ($raw.Substring($m.Length))
  foreach ($k in 'title', 'description') { if ($meta[$k]) { $meta[$k] = Expand-Tokens $meta[$k] } }
  $ld = ''
  if ($meta.crumbs) {
    $items = @(, @('Home', '/')); foreach ($c in $meta.crumbs.Split(';')) { $kv = $c.Split('='); $items += , @($kv[0], $kv[1]) }
    $ld += Script-Ld (Breadcrumb-JsonLd $items)
  }
  if ($meta.schema -eq 'showrooms') { $ld += Script-Ld (Showrooms-JsonLd) }
  if ($meta.schema -eq 'services') { $ld += Script-Ld (Services-JsonLd) }
  if ($meta.itemlist) { $ld += Script-Ld (ItemList-JsonLd $meta.itemlist) }
  if ($meta.schema -eq 'home') {
    $qa =((Read-Text "$src/data/faqs.json" | ConvertFrom-Json) | ForEach-Object { "{`"@type`":`"Question`",`"name`":$(JsonStr $_.q),`"acceptedAnswer`":{`"@type`":`"Answer`",`"text`":$(JsonStr $_.a)}}" }) -join ','
    $ld += Script-Ld "{`"@context`":`"https://schema.org`",`"@type`":`"FAQPage`",`"mainEntity`":[$qa]}"
  }
  $meta.jsonld = $ld
  $html = Assemble $meta $body
  $target = if ($meta.output) { Join-Path $out $meta.output } else { Join-Path $out (($meta.path.Trim('/') + '/index.html').TrimStart('/')) }
  Write-Text $target $html
  if ($meta.robots -notmatch 'noindex' -and -not $meta.output) { $pages += $meta.path }
  Write-Host "page  $($meta.path)"
}

foreach ($v in $vehicles) {
  if ($v.published -eq $false) { Write-Host "skip  $($v.url) (published: false)"; continue }
  Write-Text (Join-Path $out ($v.url.Trim('/') + '/index.html')) (Render-Vehicle $v)
  $pages += $v.url
  Write-Host "model $($v.url)"
}

# ---------------------------------------------------- data, seo, hosting ----
Write-Text (Join-Path $out 'assets/js/data.js') ("/* Generated by build.ps1 from src/data/*.json. Do not edit by hand. */`nwindow.AARUSH = Object.assign($($siteRaw.Trim()), {`n vehicles: $($vehRaw.Trim()),`n showrooms: $($showRaw.Trim())`n});`n")

$today = Get-Date -Format 'yyyy-MM-dd'
$urls = ($pages | Sort-Object -Unique | ForEach-Object { "  <url><loc>$BASE$_</loc><lastmod>$today</lastmod></url>" }) -join "`n"
Write-Text (Join-Path $out 'sitemap.xml') "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n$urls`n</urlset>`n"
Write-Text (Join-Path $out 'robots.txt') "User-agent: *`nAllow: /`n`nSitemap: $BASE/sitemap.xml`n"

$redirects = Read-Text "$src/data/redirects.json" | ConvertFrom-Json
$ht = @'
# Generated by build.ps1 – server settings and 301 redirects from the old WordPress URLs
AddDefaultCharset UTF-8
AddType application/manifest+json .webmanifest
ErrorDocument 404 /404.html

<IfModule mod_headers.c>
  Header always set X-Content-Type-Options "nosniff"
  Header always set Referrer-Policy "strict-origin-when-cross-origin"
  Header always set X-Frame-Options "SAMEORIGIN"
  Header always set Permissions-Policy "camera=(), microphone=(), geolocation=(self)"
</IfModule>

# Preview / staging hosts stay out of search results (never matches aarushsuzuki.in)
SetEnvIfNoCase Host "hostingersite\.com$" STAGING_HOST
<IfModule mod_headers.c>
  Header always set X-Robots-Tag "noindex, nofollow" env=STAGING_HOST
</IfModule>

RewriteEngine On

# /index.html and /folder/index.html → the folder URL
RewriteCond %{THE_REQUEST} \s/+(.*/)?index\.html[\s?] [NC]
RewriteRule ^(.*/)?index\.html$ /$1 [R=301,L]

# Old WordPress system URLs
RewriteRule ^wp-sitemap.*\.xml$ /sitemap.xml [R=301,L]
RewriteRule ^(feed|comments/feed)/?$ / [R=301,L]
RewriteRule ^(wp-admin|wp-includes|wp-json|wp-login\.php|xmlrpc\.php)(/.*)?$ - [G,L]
RewriteRule ^wp-content/ - [G,L]

# Old WordPress pages → new pages

'@
$nl = "# Generated by build.ps1 – Netlify/Cloudflare Pages format`n"
foreach ($r in $redirects) {
  $from = $r[0].Trim('/')
  $ht += "RewriteRule ^$([regex]::Escape($from))/?\s*$ $($r[1]) [R=301,L,NC,NE]`n"
  $nl += "/$from/  $($r[1])  301`n"
}
Write-Text (Join-Path $out '.htaccess') $ht
Write-Text (Join-Path $out '_redirects') $nl

# llms.txt – a plain map of the site for AI assistants and agents (generated from the same data)
$lm = "# Aarush Suzuki`n`n> Suzuki two-wheeler dealer with $(@($showrooms).Count) sales and service locations in Hyderabad and Telangana, India. Sells and services Suzuki motorcycles, scooters and the e-Access electric scooter.`n`n"
$lm += "- Sales: +91 $(Phone $site.contact.sales) · Service: +91 $(Phone $site.contact.service) · WhatsApp: +91 $(Phone $site.contact.whatsapp.Substring(2))`n"
$lm += "- Hours: Monday to Sunday, 9:30 AM to 9:30 PM`n"
$lm += "- Hyderabad: " + ((@($showrooms | Where-Object { $_.region -eq 'hyderabad' }) | ForEach-Object { $_.name }) -join ', ') + "`n"
$lm += "- Telangana: " + ((@($showrooms | Where-Object { $_.region -eq 'telangana' }) | ForEach-Object { $_.name }) -join ', ') + "`n"
$lm += "- Prices are ex-showroom Hyderabad as published by Suzuki Motorcycle India; the on-road price is quoted on request.`n"
foreach ($cg in 'motorcycles', 'scooters', 'electric', 'premium') {
  $lm += "`n## Suzuki $($CAT[$cg].plural)`n"
  foreach ($v in @($vehicles | Where-Object { $_.category -eq $cg -and $_.published -ne $false })) {
    $pf = PriceFrom $v; $p = if ($pf) { ", ex-showroom from $pf" } else { '' }
    $lm += "- [Suzuki $(AliasOf $v)]($BASE$($v.url)): $($v.summary.TrimEnd('.'))$p`n"
  }
}
$lm += "`n## Service, showrooms and booking`n- [Service centres and service booking]($BASE/services/)`n- [All showrooms: addresses, phones and directions]($BASE/contact/)`n- [Book a test ride]($BASE/book-a-test-ride/)`n`n## Optional`n- [About Aarush Suzuki]($BASE/about/)`n- [Privacy policy]($BASE/privacy-policy/)`n"
Write-Text (Join-Path $out 'llms.txt') $lm
Write-Host "Built $($pages.Count) indexable pages into $out"
