function contacts = detsub_gt(contacts, input_struct)

if ~isempty(contacts) % contacts exist to compare
    thresh = 150;
    gt = input_struct.gtimage;
    % for k = 1:length(contacts)
    % 	contacts(k).gt = 0;
    % end
    if isstruct(gt)  % ground truth in this image

        for k = 1:length(contacts) % initialize gt == 0
            contacts(k).gt = 0;
        end
        for i = 1:length(gt.x)
            if strcmpi(input_struct.side,gt.side)
                % set gt == 1 if contact is within distance threshold
                distances = sqrt( ([contacts.y] - gt.y(i)).^2 +...
                    ([contacts.x]-gt.x(i)).^2 );
                whom = find(distances < thresh);
                if ~isempty(whom)
                    for loop1 = 1:length(whom);
                        contacts(whom(loop1)).gt = 1;
                    end
                end              
                
            end
        end       
    elseif input_struct.havegt == 1 % have gt, but not in this image
        for k = 1:length(contacts)
            contacts(k).gt = 0;
        end
    else                            % no gt file present
        for k = 1:length(contacts)
            contacts(k).gt = -99;
        end
    end

end

end