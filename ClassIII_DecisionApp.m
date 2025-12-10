classdef ClassIII_DecisionApp < matlab.apps.AppBase
    % Fuzzy–AI decision system for treatment decision-making
    % in patients with skeletal Class III malocclusion.
    %
    % Z-scores are computed from reference norms.
    % H-angle and Gn–Nperp use Holdaway’s original norms
    % due to the lack of population-specific Japanese data.

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        Grid                matlab.ui.container.GridLayout

        % Input fields + Z-score labels
        ANBLabel            matlab.ui.control.Label
        ANBField            matlab.ui.control.NumericEditField
        Z_ANB_Label         matlab.ui.control.Label

        GnNpLabel           matlab.ui.control.Label
        GnNpField           matlab.ui.control.NumericEditField
        Z_GnNp_Label        matlab.ui.control.Label

        SNLabel             matlab.ui.control.Label
        SNField             matlab.ui.control.NumericEditField
        Z_SN_Label          matlab.ui.control.Label

        GoMeLabel           matlab.ui.control.Label
        GoMeField           matlab.ui.control.NumericEditField
        Z_GoMe_Label        matlab.ui.control.Label

        OJLabel             matlab.ui.control.Label
        OJField             matlab.ui.control.NumericEditField
        Z_OJ_Label          matlab.ui.control.Label

        MePPLabel           matlab.ui.control.Label
        MePPField           matlab.ui.control.NumericEditField
        Z_MePP_Label        matlab.ui.control.Label

        HAngleLabel         matlab.ui.control.Label
        HAngleField         matlab.ui.control.NumericEditField
        Z_HAngle_Label      matlab.ui.control.Label

        % Decision outputs
        ClassifyButton      matlab.ui.control.Button

        LCLabel             matlab.ui.control.Label
        LCValue             matlab.ui.control.Label

        MGLabel             matlab.ui.control.Label
        MGValue             matlab.ui.control.Label

        DecisionLabel       matlab.ui.control.Label
        DecisionValue       matlab.ui.control.Label

        ReasonLabel         matlab.ui.control.Label
        ReasonArea          matlab.ui.control.TextArea

        % ChatGPT ON/OFF
        UseChatGPTSwitch    matlab.ui.control.DropDown
    end


    % ================================================================
    % PRIVATE METHODS
    % ================================================================
    methods (Access = private)

        % ------------------------------------------------------------
        % Reference norms for Z-score calculation
        % ------------------------------------------------------------
        function norm = getNorms(~)
            % Holdaway original norms (1983)
            norm.H_mean = 10;
            norm.H_sd   = 3.5;

            % Gn–Nperp (used as N-Pog surrogate)
            norm.GnNp_mean = -2;
            norm.GnNp_sd   = 2.5;

            % Japanese population norms
            norm.SN_mean   = 72.0;  norm.SN_sd   = 4.0;
            norm.GoMe_mean = 76.6;  norm.GoMe_sd = 4.14;
            norm.OJ_mean   = 3.1;   norm.OJ_sd   = 1.07;
            norm.MePP_mean = 68.6;  norm.MePP_sd = 3.71;
            norm.ANB_mean  = 3.3;   norm.ANB_sd  = 2.4;
        end


        % ------------------------------------------------------------
        % CLASSIFY BUTTON CALLBACK
        % ------------------------------------------------------------
        function classifyButton(app, ~)

            ANB   = app.ANBField.Value;
            GnNp  = app.GnNpField.Value;
            SN    = app.SNField.Value;
            GoMe  = app.GoMeField.Value;
            OJ    = app.OJField.Value;
            MePP  = app.MePPField.Value;
            H     = app.HAngleField.Value;

            [LC, MG, decision] = app.computeDecision(ANB, GnNp, SN, GoMe, OJ, MePP, H);

            app.LCValue.Text = sprintf('%.3f', LC);
            app.MGValue.Text = sprintf('%.3f', MG);
            app.DecisionValue.Text = decision;

            if strcmp(decision,'Surgery')
                app.DecisionValue.FontColor = [0.85 0 0];
            else
                app.DecisionValue.FontColor = [0 0 0.6];
            end

            % ---- Update Z-scores ----
            norm = app.getNorms();
            app.Z_ANB_Label.Text    = sprintf("Z = %.2f",(ANB  - norm.ANB_mean )/norm.ANB_sd );
            app.Z_GnNp_Label.Text   = sprintf("Z = %.2f",(GnNp - norm.GnNp_mean)/norm.GnNp_sd);
            app.Z_SN_Label.Text     = sprintf("Z = %.2f",(SN   - norm.SN_mean  )/norm.SN_sd  );
            app.Z_GoMe_Label.Text   = sprintf("Z = %.2f",(GoMe - norm.GoMe_mean)/norm.GoMe_sd);
            app.Z_OJ_Label.Text     = sprintf("Z = %.2f",(OJ   - norm.OJ_mean  )/norm.OJ_sd  );
            app.Z_MePP_Label.Text   = sprintf("Z = %.2f",(MePP - norm.MePP_mean)/norm.MePP_sd);
            app.Z_HAngle_Label.Text = sprintf("Z = %.2f",(H    - norm.H_mean   )/norm.H_sd   );

            % ---- Reason (ChatGPT or template) ----
            if app.UseChatGPTSwitch.Value == "On"
                txt = app.generateReasonText_chatGPT( ...
                    ANB, GnNp, SN, GoMe, OJ, MePP, H, LC, MG);
            else
                txt = app.generateReasonText_template( ...
                    ANB, GnNp, SN, GoMe, OJ, MePP, H, LC, MG);
            end

            app.ReasonArea.Value = txt;
        end


        % ------------------------------------------------------------
        % DECISION MODEL (LC + fuzzy MG + decision tree)
        % ------------------------------------------------------------
        function [LC, MG, decision] = computeDecision(~, ANB, GnNp, SN, GoMe, OJ, MePP, H)

            % Linear combination (LC) for fuzzy MG-Sk3
            LC = 0.806*ANB + 0.292*GnNp + 0.181*SN - 0.160*GoMe + 3.472;

            % Fuzzy MG-Sk3 model
            if LC < 0.87
                MG = 1.0;
            else
                MG = 1.752 - 0.984*LC + 0.140*(LC^2);
            end
            MG = max(0,min(1,MG));

            % Decision tree logic (Surgery vs Camouflage)
            if OJ < -0.35
                if MG > 0.43
                    decision = "Surgery";
                else
                    decision = "Camouflage";
                end
            else
                if MePP >= 81.95
                    decision = "Surgery";
                else
                    if H < 2.6
                        decision = "Surgery";
                    else
                        decision = "Camouflage";
                    end
                end
            end
        end


        % ------------------------------------------------------------
        % TEMPLATE-BASED REASON TEXT
        % (MG-Sk3-reducing factors only)
        % ------------------------------------------------------------
        function txt = generateReasonText_template(app, ANB, GnNp, SN, GoMe, OJ, MePP, H, LC, MG)

            norm = app.getNorms();
            steps = strings(0,1);

            %% ===== Decision tree explanation =====
            if OJ < -0.35
                steps(end+1) = sprintf( ...
                    'Step 1: Overjet = %.2f mm (< -0.35 mm) → excessively negative overjet, indicating a strong surgical tendency.', OJ);

                if MG > 0.43
                    steps(end+1) = sprintf( ...
                        'MG-Sk3 = %.2f (> 0.43) → soft-tissue appearance suggests a more severe skeletal Class III pattern.', MG);
                    finalDecision = 'Surgery';
                else
                    steps(end+1) = sprintf( ...
                        'MG-Sk3 = %.2f (≤ 0.43) → soft-tissue appearance indicates mild skeletal Class III severity.', MG);
                    finalDecision = 'Camouflage';
                end

            else
                steps(end+1) = sprintf( ...
                    'Step 1: Overjet = %.2f mm (≥ -0.35 mm) → no pronounced negative overjet.', OJ);

                steps(end+1) = sprintf('Step 2: Me–PP = %.1f mm', MePP);

                zMePP = (MePP - norm.MePP_mean) / norm.MePP_sd;

                if MePP >= 81.95
                    steps(end+1) = ...
                        '→ Lower facial height is markedly larger than normal, suggesting a surgical tendency.';
                    finalDecision = 'Surgery';
                else
                    if zMePP > 1
                        steps(end+1) = sprintf( ...
                            '→ Lower facial height is slightly larger than the reference mean (Z = %.2f), but still within the camouflage range.', zMePP);
                    elseif zMePP < -1
                        steps(end+1) = sprintf( ...
                            '→ Lower facial height is smaller than the reference mean (Z = %.2f).', zMePP);
                    else
                        steps(end+1) = sprintf( ...
                            '→ Lower facial height is close to the reference mean (Z = %.2f).', zMePP);
                    end

                    steps(end+1) = sprintf('Step 3: H-angle = %.1f°', H);

                    if H < 2.6
                        steps(end+1) = ...
                            '→ The soft-tissue profile is flat or retrusive, suggesting a surgical tendency.';
                        finalDecision = 'Surgery';
                    else
                        steps(end+1) = ...
                            '→ Soft-tissue upper lip retrusion is mild, favoring camouflage treatment.';
                        finalDecision = 'Camouflage';
                    end
                end
            end

            decisionTxt = strjoin(steps, newline);

            %% ===== MG-related variables (ONLY factors that REDUCE MG-Sk3) =====
            vals = struct('z', num2cell(zeros(1,4)), 'txt', repmat({''},1,4));

            % 1) ANB (larger ANB → reduces MG-Sk3)
            zANB = (ANB - norm.ANB_mean)/norm.ANB_sd;
            if zANB > 1
                vals(1).z = zANB;
                vals(1).txt = sprintf( ...
                    'The ANB angle was larger than the normative mean (Z = %.2f). As the strongest contributor to MG-Sk3, this deviation reduced the estimated MG-Sk3 severity, which reflects the soft-tissue appearance of skeletal Class III.', ...
                    zANB);
            end

            % 2) Gn–Nperp (greater Gn–Nperp → reduces MG-Sk3)
            zGnNp = (GnNp - norm.GnNp_mean)/norm.GnNp_sd;
            if zGnNp > 1
                vals(2).z = zGnNp;
                vals(2).txt = sprintf( ...
                    'The Gn–Nperp distance was greater than the reference mean (Z = %.2f). This deviation moderately reduced the skeletal Class III soft-tissue appearance reflected in the MG-Sk3 estimate.', ...
                    zGnNp);
            end

            % 3) SN (longer SN → reduces MG-Sk3)
            zSN = (SN - norm.SN_mean)/norm.SN_sd;
            if zSN > 1
                vals(3).z = zSN;
                vals(3).txt = sprintf( ...
                    'The SN length was larger than normative values (Z = %.2f). A longer cranial base reduces sagittal discrepancy and lowers the MG-Sk3 value, contributing to a milder Class III appearance.', ...
                    zSN);
            end

            % 4) Go–Me (shorter Go–Me → reduces MG-Sk3)
            zGoMe = (GoMe - norm.GoMe_mean)/norm.GoMe_sd;
            if zGoMe < -1
                vals(4).z = abs(zGoMe);
                vals(4).txt = sprintf( ...
                    'The mandibular body length (Go–Me) was smaller than the reference mean (Z = %.2f). This deviation weakly reduced the MG-Sk3 severity.', ...
                    zGoMe);
            end

            % Sort by |Z| in descending order
            [~, idx] = sort([vals.z], 'descend');

            descList = strings(0,1);
            for k = idx
                if vals(k).z > 0 && ~isempty(vals(k).txt)
                    descList(end+1) = vals(k).txt;
                end
            end

            %% ===== MG-Sk3 summary sentence =====
            mgSentence = sprintf( ...
                'The MG-Sk3 value was %.2f, representing the fuzzy estimate of skeletal Class III severity derived from soft-tissue appearance, based on the combined influence of ANB, Gn–Nperp, SN, and Go–Me.', ...
                MG);

            %% ===== Combine as the basis for MG-Sk3 =====
            if isempty(descList)
                basisTxt = sprintf( ...
                    'As the basis for the MG-Sk3 estimation, no MG-reducing skeletal factors were identified. %s', ...
                    mgSentence);
            else
                basisTxt = sprintf( ...
                    'The following skeletal factors reduced the MG-Sk3 estimate, which reflects the soft-tissue appearance of skeletal Class III: %s %s', ...
                    strjoin(descList, ' '), mgSentence);
            end

            %% ===== Final text =====
            txt = sprintf('%s\n\nDecision: %s\n\n%s', ...
                decisionTxt, finalDecision, basisTxt);
        end


        % ------------------------------------------------------------
        % ChatGPT-based Reason Text (2–3 sentence summary)
        % ------------------------------------------------------------
        function txt = generateReasonText_chatGPT(app, ANB, GnNp, SN, GoMe, OJ, MePP, H, LC, MG)

            % 0) First, generate the rule-based template text
            baseText = app.generateReasonText_template(ANB, GnNp, SN, GoMe, OJ, MePP, H, LC, MG);

            % 1) Build prompt (single char vector for sprintf)
            prompt = sprintf( ...
                ['You are an orthodontic specialist. Condense the following diagnostic explanation ', ...
                 'into 2–3 short clinical sentences that preserve all original meaning. ', ...
                 'Focus only on the key determinants of MG-Sk3 and the rationale for the final decision. ', ...
                 'Do not introduce any new interpretations.\n\n%s'], ...
                char(baseText));

            % 2) Get API key
            apiKey = getenv('OPENAI_API_KEY');
            if isempty(apiKey)
                uialert(app.UIFigure, ...
                    'API key (OPENAI_API_KEY) is not set. Using the template-based explanation instead.', ...
                    'API Key Missing');
                txt = baseText;
                return;
            end

            % 3) Build API request
            endpoint = 'https://api.openai.com/v1/chat/completions';
            request = struct( ...
                'model', 'gpt-4o-mini', ...
                'messages', {{struct('role','user','content',prompt)}} ...
            );

            options = weboptions( ...
                'HeaderFields', { ...
                    'Content-Type'  'application/json'; ...
                    'Authorization' ['Bearer ' apiKey] ...
                }, ...
                'Timeout', 30 ...
            );

            % 4) Debug log
            disp('===== ChatGPT API Debug Log =====');
            disp(prompt);

            % 5) Call API
            txt = "";
            try
                response = webwrite(endpoint, request, options);

                disp('Response received:');
                disp(response);

                if isfield(response, 'choices') && ~isempty(response.choices)
                    choice1 = response.choices(1); % struct array → use ()
                    if isfield(choice1, 'message') && isfield(choice1.message, 'content')
                        txt = string(choice1.message.content);
                    end
                end

            catch ME
                uialert(app.UIFigure, ...
                    sprintf('ChatGPT API Error:\n%s', ME.message), ...
                    'ChatGPT Connection Error');
                txt = "";
            end

            % 6) Fallback if empty or too short
            if strlength(txt) < 5
                disp('Fallback: Using template-based Reason text.');
                txt = baseText;
            end
        end


        % ------------------------------------------------------------
        % GUI BUILD
        % ------------------------------------------------------------
        function createComponents(app)

            app.UIFigure = uifigure('Name','Class III Decision Model');
            app.UIFigure.Position = [100 100 700 720];

            % Grid Layout (20 rows)
            app.Grid = uigridlayout(app.UIFigure,[20 4]);

            RowH = repmat({30},1,20);
            for r = 14:20
                RowH{r} = '1x';
            end
            app.Grid.RowHeight = RowH;
            app.Grid.ColumnWidth = {150,120,150,120};

            % ===== Input blocks =====

            % ANB
            app.ANBLabel = uilabel(app.Grid,'Text','ANB (°)');
            app.ANBLabel.Layout.Row = 1; app.ANBLabel.Layout.Column = 1;
            app.ANBField = uieditfield(app.Grid,'numeric','Value',-3.3);
            app.ANBField.Layout.Row = 1; app.ANBField.Layout.Column = 2;
            app.Z_ANB_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_ANB_Label.Layout.Row = 2; app.Z_ANB_Label.Layout.Column = 2;

            % Gn–Nperp
            app.GnNpLabel = uilabel(app.Grid,'Text','Gn–Nperp (mm)');
            app.GnNpLabel.Layout.Row = 1; app.GnNpLabel.Layout.Column = 3;
            app.GnNpField = uieditfield(app.Grid,'numeric','Value',-5);
            app.GnNpField.Layout.Row = 1; app.GnNpField.Layout.Column = 4;
            app.Z_GnNp_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_GnNp_Label.Layout.Row = 2; app.Z_GnNp_Label.Layout.Column = 4;

            % SN
            app.SNLabel = uilabel(app.Grid,'Text','SN (mm)');
            app.SNLabel.Layout.Row = 3; app.SNLabel.Layout.Column = 1;
            app.SNField = uieditfield(app.Grid,'numeric','Value',72.8);
            app.SNField.Layout.Row = 3; app.SNField.Layout.Column = 2;
            app.Z_SN_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_SN_Label.Layout.Row = 4; app.Z_SN_Label.Layout.Column = 2;

            % Go–Me
            app.GoMeLabel = uilabel(app.Grid,'Text','Go–Me (mm)');
            app.GoMeLabel.Layout.Row = 3; app.GoMeLabel.Layout.Column = 3;
            app.GoMeField = uieditfield(app.Grid,'numeric','Value',85);
            app.GoMeField.Layout.Row = 3; app.GoMeField.Layout.Column = 4;
            app.Z_GoMe_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_GoMe_Label.Layout.Row = 4; app.Z_GoMe_Label.Layout.Column = 4;

            % Overjet
            app.OJLabel = uilabel(app.Grid,'Text','Overjet (mm)');
            app.OJLabel.Layout.Row = 5; app.OJLabel.Layout.Column = 1;
            app.OJField = uieditfield(app.Grid,'numeric','Value',-3.7);
            app.OJField.Layout.Row = 5; app.OJField.Layout.Column = 2;
            app.Z_OJ_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_OJ_Label.Layout.Row = 6; app.Z_OJ_Label.Layout.Column = 2;

            % Me–PP
            app.MePPLabel = uilabel(app.Grid,'Text','Me–PP (mm)');
            app.MePPLabel.Layout.Row = 5; app.MePPLabel.Layout.Column = 3;
            app.MePPField = uieditfield(app.Grid,'numeric','Value',78.7);
            app.MePPField.Layout.Row = 5; app.MePPField.Layout.Column = 4;
            app.Z_MePP_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_MePP_Label.Layout.Row = 6; app.Z_MePP_Label.Layout.Column = 4;

            % H-angle
            app.HAngleLabel = uilabel(app.Grid,'Text','H-angle (°)');
            app.HAngleLabel.Layout.Row = 7; app.HAngleLabel.Layout.Column = 1;
            app.HAngleField = uieditfield(app.Grid,'numeric','Value',3.0);
            app.HAngleField.Layout.Row = 7; app.HAngleField.Layout.Column = 2;
            app.Z_HAngle_Label = uilabel(app.Grid,'Text','Z = -');
            app.Z_HAngle_Label.Layout.Row = 8; app.Z_HAngle_Label.Layout.Column = 2;

            % Classify Button
            app.ClassifyButton = uibutton(app.Grid,'push','Text','Classify');
            app.ClassifyButton.ButtonPushedFcn = @(src,event) classifyButton(app,event);
            app.ClassifyButton.Layout.Row = 9;
            app.ClassifyButton.Layout.Column = [3 4];

            % Outputs
            app.LCLabel = uilabel(app.Grid,'Text','LC:','FontWeight','bold');
            app.LCLabel.Layout.Row = 10; app.LCLabel.Layout.Column = 1;

            app.LCValue = uilabel(app.Grid,'Text','-');
            app.LCValue.Layout.Row = 10; app.LCValue.Layout.Column = [2 4];

            app.MGLabel = uilabel(app.Grid,'Text','MG-Sk3:','FontWeight','bold');
            app.MGLabel.Layout.Row = 11; app.MGLabel.Layout.Column = 1;

            app.MGValue = uilabel(app.Grid,'Text','-');
            app.MGValue.Layout.Row = 11; app.MGValue.Layout.Column = [2 4];

            app.DecisionLabel = uilabel(app.Grid,'Text','Decision:','FontWeight','bold');
            app.DecisionLabel.Layout.Row = 12; app.DecisionLabel.Layout.Column = 1;

            app.DecisionValue = uilabel(app.Grid,'Text','-');
            app.DecisionValue.FontSize = 18;
            app.DecisionValue.FontWeight = 'bold';
            app.DecisionValue.Layout.Row = 12;
            app.DecisionValue.Layout.Column = [2 4];

            % ChatGPT ON/OFF
            app.UseChatGPTSwitch = uidropdown(app.Grid, ...
                'Items', {'Off','On'}, ...
                'Value', 'Off');
            app.UseChatGPTSwitch.Layout.Row = 13;
            app.UseChatGPTSwitch.Layout.Column = 3;

            % Reason text area
            app.ReasonLabel = uilabel(app.Grid,'Text','Reason:','FontWeight','bold');
            app.ReasonLabel.Layout.Row = 13; app.ReasonLabel.Layout.Column = 1;

            app.ReasonArea = uitextarea(app.Grid,'Editable','off');
            app.ReasonArea.Layout.Row = [14 20];
            app.ReasonArea.Layout.Column = [1 4];
            app.ReasonArea.FontSize = 12;
        end
    end


    % ================================================================
    % PUBLIC METHODS
    % ================================================================
    methods (Access = public)

        function app = ClassIII_DecisionApp
            createComponents(app);
            registerApp(app, app.UIFigure);
        end

        function delete(app)
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
