var addTooltipToID = function(idname, text, placement) {
    $(document).ready(function() {
        setTimeout(function() {
            shinyBS.addTooltip(idname,
                'tooltip', {
                    'placement': placement,
                    'trigger': 'hover',
                    'title': text
                }
            )
        }, 500)
    });
}
var addTooltipToClass = function(classname, text, placement) {
    document.getElementsByClassName(classname)[0].setAttribute('id', classname);
    addTooltipToID(classname, text, placement);
}
//sidebar-toggle: burger icon
//addTooltipToClass('logo', 'Welcome to the WildLift app. Please check out the help file for information on how to use this tool to support management decisions.', 'right');
//addTooltipToClass('sidebar-toggle', 'Number of years in which the caribou population is forecasted. Default set, but the user can toggle.', 'right');
