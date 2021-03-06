SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_EXECUTEREGLEMISSION
-- Paramètre d'entrée	: @v_iag_id : Identifiant de l'AGV
--			  @v_sql : SQL
--			  @v_variable : Liste de toutes les variables de la règle au format 'V1,V2,V3,...,Vn,'
--			  @v_critere : Liste de tous les critÞres de la règle au format 'C1,C2,C3,...,Cn,'
-- Paramètre de sortie	: 
-- Descriptif 		: Exécution d'une règle d'attribution de mission
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_EXECUTEREGLEMISSION] @v_iag_id tinyint, @v_sql varchar(8000), @v_variable varchar(4000), @v_critere varchar(4000)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_select varchar(8000),
	@v_idcritere integer,
	@v_idvariable integer,
	@v_charindex int,
	@v_mod_idmode int,
	@v_stopAttrib bit,
	@v_iag_decharge bit,
	@v_iag_etat bit,
	@v_transfertAutorise bit

-- Déclaration des constantes de type magasin
DECLARE
	@TYPE_AGV tinyint

-- Déclaration des constantes de type mission
DECLARE
	@TYPE_TRSF_CHARGE tinyint
	
-- Déclaration des constantes de mode d'exploitation
DECLARE
	@MODE_TEST int

-- Définition des constantes
	SET @TYPE_AGV = 1
	SET @TYPE_TRSF_CHARGE = 1
	SET @MODE_TEST = 1

	IF EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDETAT = 1 AND MIS_MARQUE = 0)
	BEGIN
		-- Récupération du mode d'exploitation de l'agv
		SELECT @v_mod_idmode = IAG_MODE_EXPLOIT FROM INFO_AGV WHERE IAG_ID = @v_iag_id
		SELECT @v_iag_decharge = IAG_DECHARGE FROM INFO_AGV WHERE IAG_ID = @v_iag_id
		IF @v_mod_idmode <> @MODE_TEST
		BEGIN
			-- Contrôle si l'attribution des missions fonctionnelles est stoppée
 			SET @v_stopAttrib = CASE WHEN ISNULL((SELECT  PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'STOP_ATTRIB'), 'TRUE') = 'TRUE' THEN 1 ELSE 0 END
			EXEC SPV_GETETATAGV @v_iag_id, @v_iag_etat out
			SET @v_transfertAutorise = CASE WHEN (@v_stopAttrib = 1 OR @v_iag_decharge = 1) AND @v_iag_etat = 0 THEN 0 ELSE 1 END
		END
		ELSE
			SET @v_transfertAutorise = 1
		IF ((@v_critere IS NOT NULL) OR (@v_variable IS NOT NULL))
		BEGIN
			SELECT @v_select = 'SELECT *'
			-- Modification de la requête avec les criteres utilisés
			IF @v_critere IS NOT NULL
			BEGIN
				SELECT @v_charindex = CHARINDEX(',', @v_critere)
				WHILE @v_charindex > 1
				BEGIN
					SELECT @v_idcritere = SUBSTRING(@v_critere, 1, @v_charindex - 1)
					IF EXISTS (SELECT 1 FROM CRITERE WHERE CRI_IDCRITERE = @v_idcritere AND CRI_DONNEE = 1)
						SELECT @v_select = @v_select + ', (SELECT CONVERT(bigint, CRM_VALUE) FROM CRITERE_MISSION WHERE CRM_IDCRITERE = '
							+ CONVERT(varchar, @v_idcritere) + ' AND CRM_IDMISSION = MIS_IDMISSION) CRITERE' + REPLACE(CONVERT(varchar, @v_idcritere),'-', '_') + 'C'
					ELSE
						SELECT @v_select = @v_select + ', (SELECT CRM_VALUE FROM CRITERE_MISSION WHERE CRM_IDCRITERE = '
							+ CONVERT(varchar, @v_idcritere) + ' AND CRM_IDMISSION = MIS_IDMISSION) CRITERE' + REPLACE(CONVERT(varchar, @v_idcritere),'-', '_') + 'C'
					SELECT @v_critere = SUBSTRING(@v_critere, @v_charindex + 1, LEN(@v_critere) - @v_charindex)
					SELECT @v_charindex = CHARINDEX(',', @v_critere)
				END
			END
			-- Modification de la requête avec les variables utilisées
			IF @v_variable IS NOT NULL
			BEGIN
				SELECT @v_charindex = CHARINDEX(',', @v_variable)
				WHILE @v_charindex > 1
				BEGIN
					SELECT @v_idvariable = SUBSTRING(@v_variable, 1, @v_charindex - 1)
					SELECT @v_select = @v_select + ', (SELECT VAR_VALUE FROM VARIABLE WHERE VAR_ID = '
						+ CONVERT(varchar, @v_idvariable) + ') VARIABLE' + REPLACE(CONVERT(varchar, @v_idvariable),'-', '_') + 'V'
					SELECT @v_variable = SUBSTRING(@v_variable, @v_charindex + 1, LEN(@v_variable) - @v_charindex)
					SELECT @v_charindex = CHARINDEX(',', @v_variable)
				END
			END
			SELECT @v_select = @v_select + ' FROM MISSION WHERE MIS_IDETAT = 1 AND MIS_MARQUE = 0'
				+ ' AND NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDMISSION = MIS_IDMISSION AND TAC_IDORDRE IS NOT NULL)'
				+ ' AND ((' + CONVERT(varchar, @v_transfertAutorise) + ' = 1) OR (' + CONVERT(varchar, @v_transfertAutorise) + ' = 0 AND (MIS_TYPEMISSION <> ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' OR (MIS_TYPEMISSION = ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' AND MIS_DECHARGE = 1 AND ' + CONVERT(varchar, @v_iag_decharge) + ' = 1))))'
			IF CHARINDEX('ORDER BY', @v_sql) = 1
				EXEC ('SELECT TOP 1 MIS_IDMISSION FROM (' + @v_select + ') Tmp ' + @v_sql)
			ELSE
				EXEC ('SELECT TOP 1 MIS_IDMISSION FROM (' + @v_select + ') Tmp WHERE ' + @v_sql)
		END
		ELSE
		BEGIN
			IF @v_sql IS NULL
				SELECT @v_sql = 'SELECT TOP 1 MIS_IDMISSION FROM MISSION WHERE MIS_IDETAT = 1 AND MIS_MARQUE = 0'
					+ ' AND NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDMISSION = MIS_IDMISSION AND TAC_IDORDRE IS NOT NULL)'
					+ ' AND ((' + CONVERT(varchar, @v_transfertAutorise) + ' = 1) OR (' + CONVERT(varchar, @v_transfertAutorise) + ' = 0 AND (MIS_TYPEMISSION <> ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' OR (MIS_TYPEMISSION = ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' AND MIS_DECHARGE = 1 AND ' + CONVERT(varchar, @v_iag_decharge) + ' = 1))))'
			ELSE
			BEGIN
				IF CHARINDEX('ORDER BY', @v_sql) = 1
					SELECT @v_sql = 'SELECT TOP 1 MIS_IDMISSION FROM MISSION WHERE MIS_IDETAT = 1 AND MIS_MARQUE = 0'
						+ ' AND NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDMISSION = MIS_IDMISSION AND TAC_IDORDRE IS NOT NULL)' 
						+ ' AND ((' + CONVERT(varchar, @v_transfertAutorise) + ' = 1) OR (' + CONVERT(varchar, @v_transfertAutorise) + ' = 0 AND (MIS_TYPEMISSION <> ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' OR (MIS_TYPEMISSION = ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' AND MIS_DECHARGE = 1 AND ' + CONVERT(varchar, @v_iag_decharge) + ' = 1)))) '+ @v_sql
				ELSE
					SELECT @v_sql = 'SELECT TOP 1 MIS_IDMISSION FROM MISSION, TACHE WHERE MIS_IDETAT = 1 AND MIS_MARQUE = 0'
						+ ' AND NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDMISSION = MIS_IDMISSION AND TAC_IDORDRE IS NOT NULL)'
						+ ' AND ((' + CONVERT(varchar, @v_transfertAutorise) + ' = 1) OR (' + CONVERT(varchar, @v_transfertAutorise) + ' = 0 AND (MIS_TYPEMISSION <> ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' OR (MIS_TYPEMISSION = ' + CONVERT(varchar, @TYPE_TRSF_CHARGE) + ' AND MIS_DECHARGE = 1 AND ' + CONVERT(varchar, @v_iag_decharge) + ' = 1)))) AND ' + @v_sql
			END
			EXEC (@v_sql)
		END
	END
	ELSE
		SELECT NULL MIS_IDMISSION


