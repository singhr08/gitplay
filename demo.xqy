xquery version "1.0-ml";

import module namespace mem = "http://xqdev.com/in-mem-update" at "/MarkLogic/appservices/utils/in-mem-update.xqy";

declare namespace n = "http://www.bbc.co.uk/nitro/";
declare namespace error = "http://marklogic.com/xdmp/error";

declare option xdmp:mapping "false";

declare function create($new-pips-doc as element(), $now as xs:dateTime, $modules as xs:string*) as empty-sequence() {
  let $new := create-entity($new-pips-doc, $now, $modules)
  return (
    attach-to-ancestor($new, (), $now, $modules)
  )
};

declare function update($old-pips-doc as element(), $new-pips-doc as element(), $now as xs:dateTime, $modules as xs:string*) as empty-sequence() {
  let $old := data-model:get-entity-metadata($old-pips-doc)
  let $new := update-entity($old-pips-doc, $new-pips-doc, $now, $modules)
  return (
    update-ancestor($old, $new, $now, $modules),
    update-descendants($old, $new, $now, $modules)
  )
};

declare function move($old-pips-doc as element(), $new-pips-doc as element(), $now as xs:dateTime, $modules as xs:string*) as empty-sequence() {
  let $old-ancestors := skeleton:call-modules($skeleton:ENTITY-MODULES, 'get-old-pips-ancestors', $old-pips-doc) 
  let $new-ancestors := skeleton:call-modules($skeleton:ENTITY-MODULES, 'get-pips-ancestors', $new-pips-doc)
  let $common-ancestors := functx:value-intersect($old-ancestors, $new-ancestors)

  let $old := data-model:get-entity-metadata($old-pips-doc)
  let $detach-from-ancestors := detach-from-ancestor($old-pips-doc, $old, $common-ancestors, $now, $modules)
  let $new := update-entity($old-pips-doc, $new-pips-doc, $now, $modules)
  return (
    attach-to-ancestor($new, $common-ancestors, $now, $modules),
    if (fn:empty($common-ancestors)) then () else update-common-ancestor($old, $new, skeleton:get-parent-pid($new/@pid), $common-ancestors, $now, $modules),
    update-descendants($old, $new, $now, $modules)
  )
};

declare function delete($old-pips-doc as element(), $now as xs:dateTime, $modules as xs:string*) as empty-sequence() {
  let $old := data-model:get-entity-metadata($old-pips-doc)
  return 
    if (fn:exists($old)) then (
      detach-from-ancestor($old-pips-doc, $old, (), $now, $modules),
      delete-entity($old, $modules)
    )
    else
      ()
};

