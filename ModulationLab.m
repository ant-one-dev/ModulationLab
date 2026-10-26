classdef ModulationLab < handle
    %MODULATIONLAB  Interactive explorer for digital modulation and coding.
    %
    %   ModulationLab          opens the application.
    %   app = ModulationLab;   also returns the application object.
    %
    %   Signal chain simulated:
    %     source (random bits / colour image) -> CRC -> FEC (Hamming /
    %     convolutional) -> line coding or digital modulation -> AWGN channel
    %     -> demodulation -> FEC decoding (Viterbi) -> CRC check -> sink
    %
    %   Everything is shown on a single screen. Only base MATLAB is used
    %   (no toolbox required).

    properties (SetAccess = private)
        UIFigure
    end

    properties (Access = private)
        % --- controls
        SourceDrop; NBitsSpin; ImgSizeDrop
        FamilyDrop; SchemeDrop; OrderDrop; SchemeDesc; RbEdit
        CrcDrop; CrcDesc; CrcLenSpin; FecDrop
        EbN0Slider; EbN0Edit; NoiseCheck
        LiveCheck; LabelsCheck; ThemeDrop
        Kpi                     % struct of value labels (top strip)
        % --- plots
        AxBits; AxTime; AxConst; AxEye; AxPSD; AxBER; AxImgTx; AxImgRx; ImgInfo
        % --- BER panel
        BerMin; BerMax; BerBits; BerUncoded
        BerHandles = gobjects(0)
        BerNames = {}
        BerCount = 0
        BerMinVal = 1
        % --- state
        Catalog
        Seed = 1
        Busy = false
        ImageRaw
        LastResult
        LastBW = NaN
    end

    properties (Constant, Access = private)
        FecItems = {'None', 'Hamming (7,4)', 'Conv. K=3 (7,5) + Viterbi', 'Conv. K=7 (171,133) + Viterbi'}
        CrcItems = {'None', 'CRC-8', 'CRC-16-CCITT'}
        SPS = 16
    end

    % =====================================================================
    methods
        function app = ModulationLab()
            root = fileparts(mfilename('fullpath'));
            addpath(genpath(fullfile(root, 'src')));
            app.Catalog = schemeCatalog();
            app.ImageRaw = loadDefaultImage();
            app.buildUI();
            app.onFamilyChanged();
            app.UIFigure.Visible = 'on';
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    % =====================================================================
    methods (Access = private)

        %% ------------------------------------------------------------ UI
        function buildUI(app)
            fig = uifigure('Name', 'ModulationLab - Digital Modulation & Coding Explorer', ...
                'Position', [30 30 1560 920], 'Visible', 'off');
            fig.CloseRequestFcn = @(~, ~) delete(app);
            app.UIFigure = fig;

            main = uigridlayout(fig, [1 2]);
            main.ColumnWidth = {320, '1x'};
            main.Padding = [8 8 8 8];
            main.ColumnSpacing = 10;

            app.buildControls(main);

            right = uigridlayout(main, [3 3]);
            right.RowHeight = {70, '1x', '1x'};
            right.ColumnWidth = {'1.15x', '1x', '1x'};
            right.Padding = [0 0 0 0];
            right.RowSpacing = 8;
            right.ColumnSpacing = 8;

            app.buildKpis(right);

            % row 2: time signals | constellation | eye
            % bits and waveform share one tiled layout so that their time
            % axes are aligned sample for sample
            tp = ModulationLab.place(uipanel(right, 'BorderType', 'none'), 2, 1);
            tl = tiledlayout(tp, 7, 1, 'TileSpacing', 'tight', 'Padding', 'tight');
            app.AxBits = nexttile(tl, 1, [2 1]);
            app.AxTime = nexttile(tl, 3, [5 1]);
            linkaxes([app.AxBits app.AxTime], 'x');
            app.AxConst = ModulationLab.place(uiaxes(right), 2, 2);
            app.AxEye = ModulationLab.place(uiaxes(right), 2, 3);

            % row 3: spectrum | BER | image
            app.AxPSD = ModulationLab.place(uiaxes(right), 3, 1);
            app.buildBerPanel(right);
            app.buildImagePanel(right);
        end

        function buildControls(app, parent)
            left = uigridlayout(parent, [6 1]);
            left.RowHeight = {40, 128, 210, 176, 130, 130};
            left.Padding = [0 0 4 0];
            left.RowSpacing = 8;
            left.Scrollable = 'on';

            uilabel(left, 'Text', sprintf('ModulationLab\nDigital modulation & channel coding explorer'), ...
                'FontSize', 13, 'FontWeight', 'bold');

            % 1 - Source
            g = ModulationLab.panelGrid(left, '1  Source', {24, 24, 24});
            app.SourceDrop = ModulationLab.field(g, 1, 'Data', ...
                uidropdown(g, 'Items', {'Random bits', 'Image'}, 'Value', 'Image'));
            app.NBitsSpin = ModulationLab.field(g, 2, 'Number of bits', ...
                uispinner(g, 'Limits', [100 1e6], 'Step', 5000, 'Value', 20000, ...
                'ValueDisplayFormat', '%.0f', 'RoundFractionalValues', 'on'));
            app.ImgSizeDrop = uidropdown(g, 'Items', {'32 x 32 px', '64 x 64 px', '128 x 128 px'}, ...
                'ItemsData', [32 64 128], 'Value', 64);
            app.ImgSizeDrop.Layout.Row = 3; app.ImgSizeDrop.Layout.Column = 2;
            b = uibutton(g, 'Text', 'Load image...', 'ButtonPushedFcn', @(~, ~) app.onLoadImage());
            b.Layout.Row = 3; b.Layout.Column = 1;

            % 2 - Modulation
            g = ModulationLab.panelGrid(left, '2  Modulation / line coding', {24, 24, 24, 52, 24});
            fams = unique({app.Catalog.family}, 'stable');
            app.FamilyDrop = ModulationLab.field(g, 1, 'Family', ...
                uidropdown(g, 'Items', fams, 'Value', 'Phase (PSK)'));
            app.SchemeDrop = ModulationLab.field(g, 2, 'Scheme', uidropdown(g, 'Items', {''}));
            app.OrderDrop = ModulationLab.field(g, 3, 'Order M', uidropdown(g, 'Items', {'-'}));
            app.SchemeDesc = uilabel(g, 'Text', '', 'WordWrap', 'on', 'FontAngle', 'italic', ...
                'VerticalAlignment', 'top');
            app.SchemeDesc.Layout.Row = 4; app.SchemeDesc.Layout.Column = [1 2];
            app.RbEdit = ModulationLab.field(g, 5, 'Bit rate (kbit/s)', ...
                uieditfield(g, 'numeric', 'Limits', [0.001 1e6], 'LowerLimitInclusive', 'on', ...
                'Value', 9.6, 'ValueDisplayFormat', '%g', ...
                'Tooltip', 'Channel bit rate R_b. Scales the time and frequency axes; at a given Eb/N0 the BER does not depend on it.'));

            % 3 - Channel coding
            g = ModulationLab.panelGrid(left, '3  Channel coding', {24, 52, 24, 24});
            app.CrcDrop = ModulationLab.field(g, 1, 'Error detection', ...
                uidropdown(g, 'Items', app.CrcItems));
            app.CrcDesc = uilabel(g, 'Text', '', 'WordWrap', 'on', 'FontAngle', 'italic', ...
                'VerticalAlignment', 'top');
            app.CrcDesc.Layout.Row = 2; app.CrcDesc.Layout.Column = [1 2];
            app.CrcLenSpin = ModulationLab.field(g, 3, 'CRC frame (bits)', ...
                uispinner(g, 'Limits', [16 4096], 'Step', 16, 'Value', 128, ...
                'ValueDisplayFormat', '%.0f', 'RoundFractionalValues', 'on'));
            app.FecDrop = ModulationLab.field(g, 4, 'Error correction', ...
                uidropdown(g, 'Items', app.FecItems));

            % 4 - Channel
            g = ModulationLab.panelGrid(left, '4  AWGN channel', {24, 36, 22});
            app.EbN0Edit = ModulationLab.field(g, 1, 'Eb/N0 (dB)', ...
                uieditfield(g, 'numeric', 'Limits', [-10 40], 'Value', 10, 'ValueDisplayFormat', '%.1f'));
            app.EbN0Slider = uislider(g, 'Limits', [-4 30], 'Value', 10, 'MajorTicks', -4:4:28, ...
                'MinorTicks', -4:1:30);
            app.EbN0Slider.Layout.Row = 2; app.EbN0Slider.Layout.Column = [1 2];
            app.NoiseCheck = uicheckbox(g, 'Text', 'Add noise', 'Value', true);
            app.NoiseCheck.Layout.Row = 3; app.NoiseCheck.Layout.Column = [1 2];

            % 5 - Actions & export
            g = uigridlayout(left, [4 2]);
            g.RowHeight = {32, 22, 28, 24}; g.Padding = [0 0 0 0]; g.RowSpacing = 6;
            b = uibutton(g, 'Text', 'Transmit (new noise)', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, ~) app.onTransmit());
            b.Layout.Column = [1 2];
            app.LiveCheck = uicheckbox(g, 'Text', 'Live update', 'Value', true);
            app.LabelsCheck = uicheckbox(g, 'Text', 'Show bit labels', 'Value', false, ...
                'ValueChangedFcn', @(~, ~) app.redrawConstellation());
            uibutton(g, 'Text', 'Export PNG...', 'ButtonPushedFcn', @(~, ~) app.onExportPng());
            uibutton(g, 'Text', 'Export GIF...', 'ButtonPushedFcn', @(~, ~) app.onExportGif());
            uilabel(g, 'Text', 'Theme');
            app.ThemeDrop = uidropdown(g, 'Items', {'Auto', 'Light', 'Dark'}, ...
                'ValueChangedFcn', @(~, ~) app.onTheme());

            % callbacks that trigger a new simulation
            ctrls = {app.SourceDrop, app.NBitsSpin, app.ImgSizeDrop, app.OrderDrop, ...
                app.RbEdit, app.CrcDrop, app.CrcLenSpin, app.FecDrop, app.NoiseCheck};
            for i = 1:numel(ctrls)
                ctrls{i}.ValueChangedFcn = @(~, ~) app.onSettingChanged();
            end
            app.FamilyDrop.ValueChangedFcn = @(~, ~) app.onFamilyChanged();
            app.SchemeDrop.ValueChangedFcn = @(~, ~) app.onSchemeChanged();
            app.EbN0Edit.ValueChangedFcn = @(~, ~) app.onEbN0Edit();
            app.EbN0Slider.ValueChangedFcn = @(~, ~) app.onSlider(app.EbN0Slider.Value);
            app.EbN0Slider.ValueChangingFcn = @(~, evt) app.onSlider(evt.Value);
        end

        function buildKpis(app, parent)
            names = {'ber', 'Bit error rate'; 'err', 'Bit errors'; 'raw', 'Raw channel BER'; ...
                'th', 'Theoretical BER'; 'crc', 'CRC failed frames'; 'rate', 'Code rate'; ...
                'bw', 'Bandwidth B99'; 'eff', 'Spectral efficiency'};
            g = uigridlayout(parent, [1 size(names, 1)]);
            g.Layout.Row = 1; g.Layout.Column = [1 3];
            g.Padding = [0 0 0 0];
            g.ColumnSpacing = 8;
            for i = 1:size(names, 1)
                pg = uigridlayout(uipanel(g), [2 1]);
                pg.RowHeight = {'1x', 16};
                pg.Padding = [4 4 4 4];
                pg.RowSpacing = 2;
                app.Kpi.(names{i, 1}) = uilabel(pg, 'Text', '-', 'FontSize', 18, ...
                    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
                uilabel(pg, 'Text', names{i, 2}, 'FontSize', 11, 'HorizontalAlignment', 'center');
            end
        end

        function buildBerPanel(app, parent)
            p = ModulationLab.place(uipanel(parent, 'Title', 'BER curve', 'FontWeight', 'bold'), 3, 2);
            g = uigridlayout(p, [3 1]);
            g.RowHeight = {26, 24, '1x'}; g.Padding = [6 4 6 4]; g.RowSpacing = 4;
            b = uigridlayout(g, [1 3]);
            b.Padding = [0 0 0 0]; b.ColumnSpacing = 6;
            b.ColumnWidth = {'1x', '1.3x', 60};
            uibutton(b, 'Text', 'Run BER', 'FontWeight', 'bold', 'ButtonPushedFcn', @(~, ~) app.onRunBER(false));
            uibutton(b, 'Text', 'Add to comparison', 'ButtonPushedFcn', @(~, ~) app.onRunBER(true));
            uibutton(b, 'Text', 'Clear', 'ButtonPushedFcn', @(~, ~) app.clearBER());
            c = uigridlayout(g, [1 7]);
            c.Padding = [0 0 0 0]; c.ColumnSpacing = 4;
            c.ColumnWidth = {'fit', 38, 'fit', 38, 'fit', 62, 'fit'};
            uilabel(c, 'Text', 'Eb/N0');
            app.BerMin = uieditfield(c, 'numeric', 'Value', 0);
            uilabel(c, 'Text', 'to');
            app.BerMax = uieditfield(c, 'numeric', 'Value', 14);
            uilabel(c, 'Text', 'dB, bits');
            app.BerBits = uieditfield(c, 'numeric', 'Value', 30000, 'Limits', [1000 1e7], ...
                'RoundFractionalValues', 'on', 'ValueDisplayFormat', '%.0f');
            app.BerUncoded = uicheckbox(c, 'Text', '+ uncoded', 'Value', true);
            app.AxBER = uiaxes(g);
            app.clearBER();
        end

        function buildImagePanel(app, parent)
            p = ModulationLab.place(uipanel(parent, 'Title', 'Image transmission', 'FontWeight', 'bold'), 3, 3);
            g = uigridlayout(p, [2 2]);
            g.RowHeight = {'1x', 34}; g.Padding = [4 4 4 4]; g.RowSpacing = 2; g.ColumnSpacing = 4;
            app.AxImgTx = uiaxes(g);
            app.AxImgRx = uiaxes(g);
            app.ImgInfo = uilabel(g, 'Text', '', 'HorizontalAlignment', 'center', 'WordWrap', 'on', ...
                'FontSize', 11);
            app.ImgInfo.Layout.Column = [1 2];
        end

        %% ----------------------------------------------------- callbacks
        function onFamilyChanged(app)
            sel = strcmp({app.Catalog.family}, app.FamilyDrop.Value);
            names = {app.Catalog(sel).name};
            app.SchemeDrop.Items = names;
            pref = intersect({'M-PSK', 'OOK', 'BFSK', 'Manchester', '16-QAM'}, names, 'stable');
            app.SchemeDrop.Value = pref{1};
            app.onSchemeChanged();
        end

        function onSchemeChanged(app)
            s = app.Catalog(strcmp({app.Catalog.name}, app.SchemeDrop.Value));
            if isempty(s.orders)
                app.OrderDrop.Items = {'-'};
                app.OrderDrop.ItemsData = {};
                app.OrderDrop.Enable = 'off';
            else
                app.OrderDrop.Items = arrayfun(@num2str, s.orders, 'UniformOutput', false);
                app.OrderDrop.ItemsData = s.orders;
                app.OrderDrop.Value = s.orders(min(2, numel(s.orders)));   % 4-PSK / 8-ASK by default
                app.OrderDrop.Enable = 'on';
            end
            app.onSettingChanged();
        end

        function onSettingChanged(app)
            app.updateEnable();
            if app.LiveCheck.Value
                app.update();
            end
        end

        function onSlider(app, v)
            app.EbN0Edit.Value = round(v * 2) / 2;          % 0.5 dB steps
            if app.LiveCheck.Value
                app.update();
            end
        end

        function onEbN0Edit(app)
            lim = app.EbN0Slider.Limits;
            app.EbN0Slider.Value = min(max(app.EbN0Edit.Value, lim(1)), lim(2));
            if app.LiveCheck.Value
                app.update();
            end
        end

        function onTransmit(app)
            app.Seed = app.Seed + 1;
            app.update();
        end

        function onLoadImage(app)
            [f, p] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Images'}, 'Choose an image');
            figure(app.UIFigure);
            if isequal(f, 0), return; end
            try
                app.ImageRaw = imread(fullfile(p, f));
            catch err
                uialert(app.UIFigure, err.message, 'Cannot read image');
                return
            end
            app.SourceDrop.Value = 'Image';
            app.onSettingChanged();
        end

        function onTheme(app)
            try
                theme(app.UIFigure, lower(app.ThemeDrop.Value));
            catch
                uialert(app.UIFigure, 'Themes need MATLAB R2025a or newer.', 'Theme');
                app.ThemeDrop.Value = 'Auto';
            end
        end

        function updateEnable(app)
            sch = getScheme(app.schemeName());
            isImg = strcmp(app.SourceDrop.Value, 'Image');
            app.NBitsSpin.Enable = ~isImg;
            app.ImgSizeDrop.Enable = isImg;
            app.CrcLenSpin.Enable = ~strcmp(app.CrcDrop.Value, 'None');
            app.SchemeDesc.Text = sch.desc;
            app.CrcDesc.Text = ModulationLab.crcHelp(app.CrcDrop.Value);
        end

        %% ---------------------------------------------------- simulation
        function name = schemeName(app)
            % Concrete scheme name, e.g. '8-PSK' for the template 'M-PSK'
            name = app.SchemeDrop.Value;
            if strncmp(name, 'M-', 2)
                name = sprintf('%d-%s', app.OrderDrop.Value, name(3:end));
            end
        end

        function cfg = getConfig(app)
            cfg = defaultConfig(struct( ...
                'scheme', app.schemeName(), ...
                'EbN0dB', app.EbN0Edit.Value, ...
                'noise', app.NoiseCheck.Value, ...
                'sps', app.SPS, ...
                'Rb', 1e3 * app.RbEdit.Value, ...
                'crc', app.CrcDrop.Value, ...
                'crcFrameLen', app.CrcLenSpin.Value, ...
                'fec', app.FecDrop.Value));
        end

        function [bits, px] = getSourceBits(app)
            rng(app.Seed, 'twister');
            px = [];
            if strcmp(app.SourceDrop.Value, 'Image')
                px = prepareImage(app.ImageRaw, app.ImgSizeDrop.Value);
                bits = imageToBits(px);
            else
                bits = randi([0 1], app.NBitsSpin.Value, 1);
            end
        end

        function update(app)
            if app.Busy, return; end
            app.Busy = true;
            cleaner = onCleanup(@() app.setIdle());
            try
                cfg = app.getConfig();
                [bits, px] = app.getSourceBits();
                res = runChain(cfg, bits);
                app.LastResult = res;
                plotTimeSignals(app.AxBits, app.AxTime, res);
                plotConstellation(app.AxConst, res, app.LabelsCheck.Value);
                app.LastBW = plotSpectrum(app.AxPSD, res);
                plotEye(app.AxEye, res);
                app.fillKpis(res);
                app.drawImage(res, px);
            catch err
                uialert(app.UIFigure, err.message, 'Simulation error');
            end
            drawnow limitrate;
        end

        function setIdle(app)
            if isvalid(app), app.Busy = false; end
        end

        function redrawConstellation(app)
            if ~isempty(app.LastResult)
                plotConstellation(app.AxConst, app.LastResult, app.LabelsCheck.Value);
            end
        end

        function fillKpis(app, res)
            K = app.Kpi;
            if res.nErr == 0
                K.ber.Text = sprintf('< %.0e', 1/res.nInfo);
            else
                K.ber.Text = sprintf('%.2e', res.ber);
            end
            K.ber.FontColor = ModulationLab.berColor(res.ber);
            K.err.Text = sprintf('%d / %d', res.nErr, res.nInfo);
            if res.rawErr == 0
                K.raw.Text = '0';
            else
                K.raw.Text = sprintf('%.2e', res.rawBER);
            end
            if isempty(res.theory)
                K.th.Text = 'n/a';
            else
                K.th.Text = sprintf('%.2e', res.theory);
            end
            if res.crcFrames == 0
                K.crc.Text = 'off';
            elseif res.crcUndetected > 0
                K.crc.Text = sprintf('%d / %d (%d missed)', res.crcFail, res.crcFrames, res.crcUndetected);
            else
                K.crc.Text = sprintf('%d / %d', res.crcFail, res.crcFrames);
            end
            K.rate.Text = sprintf('%.3f', res.codeRate);
            K.bw.Text = fmtEng(app.LastBW * res.cfg.Rb, 'Hz');
            K.eff.Text = sprintf('%.2f b/s/Hz', res.codeRate / app.LastBW);
        end

        function drawImage(app, res, px)
            axs = [app.AxImgTx app.AxImgRx];
            for ax = axs
                cla(ax);
                ax.XTick = []; ax.YTick = [];
                box(ax, 'on');
            end
            if isempty(px)
                title(app.AxImgTx, 'Transmitted');
                title(app.AxImgRx, 'Received');
                app.ImgInfo.Text = 'Set Data to "Image" (section 1) to send a colour picture through the chain.';
                return
            end
            rxPx = bitsToImage(res.rxBits, size(px));
            mse = mean((double(px(:)) - double(rxPx(:))).^2);
            image(app.AxImgTx, px);
            image(app.AxImgRx, rxPx);
            for ax = axs
                axis(ax, 'image');
                ax.XTick = []; ax.YTick = [];
            end
            title(app.AxImgTx, 'Transmitted');
            title(app.AxImgRx, 'Received');
            if mse == 0
                q = 'perfect copy';
            else
                q = sprintf('PSNR %.1f dB', 10*log10(255^2 / mse));
            end
            app.ImgInfo.Text = sprintf('%d x %d px, %d bits (24 bits/pixel)\n%d bit errors, %s', ...
                size(px, 1), size(px, 2), res.nInfo, res.nErr, q);
        end

        %% ------------------------------------------------------ BER plot
        function clearBER(app)
            ax = app.AxBER;
            cla(ax);
            legend(ax, 'off');
            app.BerHandles = gobjects(0);
            app.BerNames = {};
            app.BerCount = 0;
            app.BerMinVal = 1;
            ax.YScale = 'log';
            ax.YLim = [1e-5 1];
            ax.XLim = [app.BerMin.Value app.BerMax.Value];
            grid(ax, 'on'); box(ax, 'on');
            xlabel(ax, 'E_b/N_0 per information bit (dB)');
            ylabel(ax, 'Bit error rate');
            title(ax, 'Dotted: theory');
        end

        function onRunBER(app, add)
            if ~add, app.clearBER(); end
            cfg = app.getConfig();
            eb = app.BerMin.Value : 1 : app.BerMax.Value;
            if numel(eb) < 2
                uialert(app.UIFigure, 'The Eb/N0 range must span at least 1 dB.', 'BER curve');
                return
            end
            nb = app.BerBits.Value;
            coded = ~strcmp(cfg.fec, 'None') || ~strcmp(cfg.crc, 'None');
            doUnc = app.BerUncoded.Value && coded;
            total = numel(eb) * (1 + doUnc);
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'BER simulation', 'Cancelable', 'on');
            cleaner = onCleanup(@() close(dlg));
            rng('shuffle');

            ber = simulateBER(cfg, eb, nb, @(i, ~) ModulationLab.progress(dlg, i-1, total, cfg.scheme, eb(i)));
            berU = [];
            if doUnc && ~dlg.CancelRequested
                cu = cfg; cu.fec = 'None'; cu.crc = 'None';
                berU = simulateBER(cu, eb, nb, @(i, ~) ModulationLab.progress(dlg, numel(eb)+i-1, ...
                    total, [cfg.scheme ' (uncoded)'], eb(i)));
            end

            ax = app.AxBER;
            col = lines(7);
            app.BerCount = app.BerCount + 1;
            cc = col(mod(app.BerCount - 1, 7) + 1, :);
            hold(ax, 'on');
            ef = linspace(eb(1), eb(end), 200);
            th = theoreticalBER(cfg.scheme, ef);
            if ~isempty(th)
                semilogy(ax, ef, th, ':', 'Color', cc, 'LineWidth', 1.3);
            end
            if ~isempty(berU)
                app.BerHandles(end+1) = semilogy(ax, eb, ModulationLab.nz(berU), 's--', 'Color', cc, ...
                    'LineWidth', 1, 'MarkerSize', 4);
                app.BerNames{end+1} = sprintf('%s uncoded', cfg.scheme);
            end
            app.BerHandles(end+1) = semilogy(ax, eb, ModulationLab.nz(ber), 'o-', 'Color', cc, ...
                'LineWidth', 1.6, 'MarkerFaceColor', cc, 'MarkerSize', 4);
            if coded
                app.BerNames{end+1} = sprintf('%s + %s', cfg.scheme, ModulationLab.codingLabel(cfg));
            else
                app.BerNames{end+1} = cfg.scheme;
            end
            hold(ax, 'off');

            vals = [ber(:); berU(:)];
            lo = min([vals(vals > 0); app.BerMinVal; 1/nb]);
            app.BerMinVal = lo;
            ax.YLim = [10^floor(log10(lo)) 1];
            ax.XLim = [min(ax.XLim(1), eb(1)) max(ax.XLim(2), eb(end))];
            legend(ax, app.BerHandles, app.BerNames, 'Location', 'southwest', 'FontSize', 8);
        end

        %% ------------------------------------------------------- export
        function onExportPng(app)
            [f, p] = uiputfile('*.png', 'Export window as PNG', 'ModulationLab.png');
            figure(app.UIFigure);
            if isequal(f, 0), return; end
            exportapp(app.UIFigure, fullfile(p, f));
        end

        function onExportGif(app)
            cfg = app.getConfig();
            [f, p] = uiputfile('*.gif', 'Export animation', ...
                sprintf('%s.gif', regexprep(cfg.scheme, '\W', '')));
            figure(app.UIFigure);
            if isequal(f, 0), return; end
            cfg.noise = true;
            rng(app.Seed, 'twister');
            bits = randi([0 1], 6000, 1);
            ebs = [24:-1:0, 1:23];
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Exporting GIF', 'Cancelable', 'on');
            cleaner = onCleanup(@() close(dlg));
            exportConstellationGif(fullfile(p, f), cfg, bits, app.Seed, ebs, ...
                @(i, n) ModulationLab.progress(dlg, i-1, n, cfg.scheme, ebs(i)));
        end
    end

    % =====================================================================
    methods (Static, Access = private)
        function c = place(c, row, col)
            c.Layout.Row = row;
            c.Layout.Column = col;
        end

        function g = panelGrid(parent, ttl, heights)
            p = uipanel(parent, 'Title', ttl, 'FontWeight', 'bold');
            g = uigridlayout(p, [numel(heights) 2]);
            g.RowHeight = heights;
            g.ColumnWidth = {108, '1x'};
            g.RowSpacing = 6;
            g.Padding = [8 6 8 6];
        end

        function ctrl = field(g, row, txt, ctrl)
            l = uilabel(g, 'Text', txt);
            l.Layout.Row = row; l.Layout.Column = 1;
            ctrl.Layout.Row = row; ctrl.Layout.Column = 2;
        end

        function txt = crcHelp(type)
            switch type
                case 'CRC-8'
                    txt = ['8 check bits per frame (x^8+x^2+x+1). Catches every burst of up to 8 bits ' ...
                        'and any odd number of errors; about 1 in 256 badly corrupted frames slips through.'];
                case 'CRC-16-CCITT'
                    txt = ['16 check bits per frame (x^16+x^12+x^5+1). Catches every burst of up to 16 bits ' ...
                        'and any odd number of errors; about 1 in 65,536 badly corrupted frames slips through.'];
                otherwise
                    txt = 'No error detection: corrupted frames are delivered without warning.';
            end
        end

        function ok = progress(dlg, done, total, name, eb)
            dlg.Value = min(1, done / total);
            dlg.Message = sprintf('%s   -   Eb/N0 = %.1f dB', name, eb);
            drawnow limitrate;
            ok = ~dlg.CancelRequested;
        end

        function y = nz(y)
            y(y == 0) = NaN;     % zero errors cannot be shown on a log scale
        end

        function s = codingLabel(cfg)
            parts = {};
            if ~strcmp(cfg.crc, 'None'), parts{end+1} = cfg.crc; end
            if ~strcmp(cfg.fec, 'None'), parts{end+1} = regexprep(cfg.fec, ' \+ Viterbi', ''); end
            if isempty(parts), s = 'uncoded'; else, s = strjoin(parts, ' + '); end
        end

        function c = berColor(ber)
            if ber < 1e-4
                c = [0.15 0.65 0.30];
            elseif ber < 1e-2
                c = [0.90 0.55 0.05];
            else
                c = [0.85 0.20 0.20];
            end
        end
    end
end
