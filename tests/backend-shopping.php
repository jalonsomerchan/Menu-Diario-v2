<?php
require $argv[1];
function check($condition, $label) {
    if (!$condition) throw new Exception($label);
    echo "PASS: $label\n";
}
$names = array('Tortilla', 'Lentejas', 'Crema');
$parsed = MenudiarioShopping::generatedIngredients($names, array(
    array('name' => 'Lentejas', 'ingredients' => array('Lentejas', 'Cebolla')),
    array('name' => 'Tortilla', 'ingredients' => array('Patatas', 'Huevos')),
    array('name' => 'Nombre inventado', 'ingredients' => array('Error')),
));
check($parsed['tortilla'] === array('Patatas', 'Huevos'), 'reordered AI results match by name');
check($parsed['lentejas'] === array('Lentejas', 'Cebolla'), 'each dish keeps its own ingredients');
check(!isset($parsed['crema']), 'missing dishes never borrow ingredients by position');
check(!isset($parsed['nombre inventado']), 'unrequested names are ignored');
$parsed = MenudiarioShopping::generatedIngredients(array('Crema de verduras'), array(
    array('name' => '  Crema   de verduras ', 'ingredients' => array('Calabaza', ' calabaza ', array('name' => 'Error'), '', 'Cebolla')),
));
check($parsed['crema de verduras'] === array('calabaza', 'Cebolla'), 'whitespace, duplicate ingredients and invalid values are handled');
$mine = array('id' => 1, 'name' => 'Tortilla', 'is_mine' => true, 'ingredients' => array('Huevos'));
$other = array('id' => 2, 'name' => 'Tortilla', 'is_mine' => false, 'ingredients' => array());
check(MenudiarioShopping::catalog(array($mine, $other))['tortilla']['id'] === 1, 'own saved recipe wins over duplicate');
check(MenudiarioShopping::catalog(array($other, $mine))['tortilla']['id'] === 1, 'catalog order does not change recipe');
