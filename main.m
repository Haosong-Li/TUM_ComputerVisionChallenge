% main.m
disp('Starting Satellite Imagery Change Detection App...');
requiredTexture = fullfile(pwd, 'Textures', 'earthmap.jpg');

if ~isfile(requiredTexture)
    error('Required texture image not found: %s', requiredTexture);
end

app = GUI;
