function [sel, ok] = get_format_dlg(file_formats)
[sel, ok] = listdlg('ListString', file_formats, 'SelectionMode', 'single', ...
    'PromptString', 'Choose a file format;', 'OKString', 'Continue');
end