SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_REGLECONDITION
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_reg_idregle : Règle
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_sql : SQL
--			  @v_arc_idlstcondition : Utilisation interne lors de l'appel récursif
--			  @v_lcn_position: Utilisation interne lors de l'appel récursif
-- Descriptif		: Gestion du texte SQL d'un filtre
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_REGLECONDITION]
	@v_action smallint,
	@v_reg_idregle int,
	@v_lan_id varchar(3),
	@v_sql varchar(8000) out,
	@v_arc_idlstcondition int out,
	@v_lcn_position tinyint,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int,
	@v_lcn_typeitem tinyint,
	@v_lcn_idsslstcondition int,
	@v_lir_idlieur tinyint,
	@v_lir_libelle varchar(50),
	@v_lir_idlieur_tmp tinyint,
	@v_lir_libelle_tmp varchar(50),
	@v_cdt_idcondition int,
	@v_filtre varchar(8000),
	@v_filtre1 varchar(8000),
	@v_filtre2 varchar(8000),
	@v_cri_idcritere int,
	@v_var_id int,
	@v_libelle varchar(8000),
	@v_opr_idoperateur tinyint,
	@v_opr_libelle varchar(40),
	@v_cdt_texte varchar(4000),
	@v_charindex int,
	@v_charindex_tmp int,
	@v_i int,
	@v_j int

	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_sql = ''
		DECLARE c_filtre CURSOR LOCAL FOR SELECT LCN_TYPEITEM, LCN_IDSSLSTCONDITION, LIR_IDLIEUR, LIR_LIBELLE,
			'"' + CASE WHEN CDT_IDCRITERE IS NOT NULL THEN (SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = CRI_IDTRADUCTIONLIBELLE)
			WHEN CDT_VARIABLE IS NOT NULL THEN (SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = VAR_IDTRADUCTIONLIBELLE) END
			+ '"' + ' ' + OPR_LIBELLE + ' ' + CASE WHEN CDT_IDTRADUCTIONTEXTE IS NOT NULL THEN (SELECT LIB_LIBELLE FROM LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = CDT_IDTRADUCTIONTEXTE)
			ELSE CDT_VALEUR END
			FROM ASSOCIATION_REGLE_CONDITION, LISTE_CONDITION
			LEFT OUTER JOIN CONDITION ON CDT_IDCONDITION = LCN_IDCONDITION
			LEFT OUTER JOIN OPERATEUR ON OPR_IDOPERATEUR = CDT_IDOPERATEUR
			LEFT OUTER JOIN CRITERE ON CRI_IDCRITERE = CDT_IDCRITERE
			LEFT OUTER JOIN VARIABLE ON VAR_ID = CDT_VARIABLE
			LEFT OUTER JOIN LIEUR ON LIR_IDLIEUR = LCN_IDLIEUR
			WHERE ARC_IDREGLE = @v_reg_idregle AND LCN_IDLSTCONDITION = ARC_IDLSTCONDITION
			AND ((ARC_TYPE = 1 AND @v_arc_idlstcondition IS NULL) OR (ARC_TYPE = 0 AND ARC_IDLSTCONDITION = @v_arc_idlstcondition))
			ORDER BY LCN_POSITION
		OPEN c_filtre
		FETCH NEXT FROM c_filtre INTO @v_lcn_typeitem, @v_lcn_idsslstcondition, @v_lir_idlieur, @v_lir_libelle, @v_filtre
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @v_lcn_typeitem = 0
			BEGIN
				IF @v_lir_idlieur IS NOT NULL
					SELECT @v_sql = '(' + @v_sql + ' ' + @v_lir_libelle + ' ' + '(' + @v_filtre + ')' + ')'
				ELSE
					SELECT @v_sql = '(' + @v_filtre + ')'
			END
			ELSE IF @v_lcn_typeitem = 1
			BEGIN
				EXEC @v_error = CFG_REGLECONDITION 0, @v_reg_idregle, @v_lan_id, @v_filtre out, @v_lcn_idsslstcondition, 0, @v_retour out
				IF @v_error = 0
				BEGIN
					IF @v_lir_idlieur IS NOT NULL
						SELECT @v_sql = '(' + @v_sql + ' ' + @v_lir_libelle + ' ' + @v_filtre + ')'
					ELSE
						SELECT @v_sql = @v_filtre
				END
			END
			FETCH NEXT FROM c_filtre INTO @v_lcn_typeitem, @v_lcn_idsslstcondition, @v_lir_idlieur, @v_lir_libelle, @v_filtre
		END
		CLOSE c_filtre
		DEALLOCATE c_filtre
		IF @v_sql = ''
			SELECT @v_sql = '...'
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	ELSE IF @v_action = 1
	BEGIN
		BEGIN TRAN
		IF @v_sql = '...'
			SELECT @v_sql = ''
		DELETE LISTE_CONDITION WHERE LCN_IDLSTCONDITION IN (SELECT ARC_IDLSTCONDITION
			FROM ASSOCIATION_REGLE_CONDITION WHERE ARC_IDREGLE = @v_reg_idregle)
		DELETE ASSOCIATION_REGLE_CONDITION WHERE ARC_IDREGLE = @v_reg_idregle
		IF @v_sql <> ''
		BEGIN
			SELECT @v_arc_idlstcondition = CASE SIGN(MIN(ARC_IDLSTCONDITION)) WHEN -1 THEN MIN(ARC_IDLSTCONDITION) - 1 ELSE -1 END FROM ASSOCIATION_REGLE_CONDITION
			INSERT INTO ASSOCIATION_REGLE_CONDITION (ARC_IDLSTCONDITION, ARC_IDREGLE, ARC_TYPE, ARC_SYSTEME) VALUES (@v_arc_idlstcondition, @v_reg_idregle, 1, 0)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				EXEC @v_error = CFG_REGLECONDITION 2, @v_reg_idregle, @v_lan_id, @v_sql out, @v_arc_idlstcondition, 0, @v_retour out
		END
		IF ((@v_retour = 113) AND (@v_error = 0))
			SELECT @v_retour = 0
		IF ((@v_retour <> 0) OR (@v_error <> 0))
			ROLLBACK TRAN
		ELSE
			COMMIT TRAN
	END
	ELSE IF @v_action = 2
	BEGIN
		SELECT @v_sql = SUBSTRING(@v_sql, 2, LEN(@v_sql) - 2)
		IF SUBSTRING(@v_sql, 1, 1) = '"'
		BEGIN
			DECLARE c_operateur CURSOR LOCAL FOR SELECT OPR_IDOPERATEUR, OPR_LIBELLE FROM OPERATEUR
			OPEN c_operateur
			FETCH NEXT FROM c_operateur INTO @v_opr_idoperateur, @v_opr_libelle
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @v_charindex = CHARINDEX(' ' + @v_opr_libelle + ' ', @v_sql)
				IF @v_charindex <> 0
				BEGIN
					SELECT @v_libelle = SUBSTRING(@v_sql, 2, @v_charindex - 3)
					SELECT @v_cdt_texte = SUBSTRING(@v_sql, @v_charindex + LEN(@v_opr_libelle) + 2, LEN(@v_sql) - @v_charindex - LEN(@v_opr_libelle))
					BREAK
				END
				FETCH NEXT FROM c_operateur INTO @v_opr_idoperateur, @v_opr_libelle
			END
			CLOSE c_operateur
			DEALLOCATE c_operateur
			SELECT TOP 1 @v_cri_idcritere = CRI_IDCRITERE FROM CRITERE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_libelle AND CRI_IDTRADUCTIONLIBELLE = LIB_TRADUCTION
			IF @@ROWCOUNT <> 0
			BEGIN
				SELECT @v_cdt_idcondition = CDT_IDCONDITION FROM CONDITION WHERE CDT_IDCRITERE = @v_cri_idcritere
					AND CDT_IDOPERATEUR = @v_opr_idoperateur AND ((CDT_IDTRADUCTIONTEXTE IS NOT NULL
					AND EXISTS (SELECT 1 FROM LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_cdt_texte AND LIB_TRADUCTION = CDT_IDTRADUCTIONTEXTE))
					OR (CDT_IDTRADUCTIONTEXTE IS NULL AND CDT_VALEUR = @v_cdt_texte))
				IF @@ROWCOUNT <> 0
				BEGIN
					INSERT INTO LISTE_CONDITION (LCN_IDLSTCONDITION, LCN_POSITION, LCN_TYPEITEM, LCN_IDCONDITION, LCN_SYSTEME)
						VALUES (@v_arc_idlstcondition, @v_lcn_position, 0, @v_cdt_idcondition, 0)
					SELECT @v_error = @@ERROR
				END
				ELSE
					SELECT @v_retour = 116
			END
			ELSE
			BEGIN
				SELECT TOP 1 @v_var_id = VAR_ID FROM VARIABLE, LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_libelle AND VAR_IDTRADUCTIONLIBELLE = LIB_TRADUCTION
				IF @@ROWCOUNT <> 0
				BEGIN
					SELECT @v_cdt_idcondition = CDT_IDCONDITION FROM CONDITION WHERE CDT_VARIABLE = @v_var_id
						AND CDT_IDOPERATEUR = @v_opr_idoperateur AND ((CDT_IDTRADUCTIONTEXTE IS NOT NULL
						AND EXISTS (SELECT 1 FROM LIBELLE WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_cdt_texte AND LIB_TRADUCTION = CDT_IDTRADUCTIONTEXTE))
						OR (CDT_IDTRADUCTIONTEXTE IS NULL AND CDT_VALEUR = @v_cdt_texte))
					IF @@ROWCOUNT <> 0
					BEGIN
						INSERT INTO LISTE_CONDITION (LCN_IDLSTCONDITION, LCN_POSITION, LCN_TYPEITEM, LCN_IDCONDITION, LCN_SYSTEME)
							VALUES (@v_arc_idlstcondition, @v_lcn_position, 0, @v_cdt_idcondition, 0)
						SELECT @v_error = @@ERROR
					END
					ELSE
						SELECT @v_retour = 116
				END
				ELSE
					SELECT @v_retour = 116
			END
		END
		ELSE IF SUBSTRING(@v_sql, 1, 1) = '('
		BEGIN
			SELECT @v_i = 1
			SELECT @v_j = 2
			WHILE @v_j <= LEN(@v_sql)
			BEGIN
				IF SUBSTRING(@v_sql, @v_j, 1) = '('
					SELECT @v_i = @v_i + 1
				ELSE IF SUBSTRING(@v_sql, @v_j, 1) = ')'
				BEGIN
					SELECT @v_i = @v_i - 1
					IF @v_i = 0
						BREAK
				END
				SELECT @v_j = @v_j + 1
			END
			SELECT @v_charindex = 0
			DECLARE c_lieur CURSOR LOCAL FOR SELECT LIR_IDLIEUR, LIR_LIBELLE FROM LIEUR
			OPEN c_lieur
			FETCH NEXT FROM c_lieur INTO @v_lir_idlieur_tmp, @v_lir_libelle_tmp
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @v_charindex_tmp = CHARINDEX(' ' + @v_lir_libelle_tmp + ' ', @v_sql, @v_j + 1)
				IF (@v_charindex = 0) OR (@v_charindex > @v_charindex_tmp AND @v_charindex_tmp <> 0)
				BEGIN
					SELECT @v_charindex = @v_charindex_tmp
					SELECT @v_lir_idlieur = @v_lir_idlieur_tmp
					SELECT @v_lir_libelle = @v_lir_libelle_tmp
				END
				FETCH NEXT FROM c_lieur INTO @v_lir_idlieur_tmp, @v_lir_libelle_tmp
			END
			CLOSE c_lieur
			DEALLOCATE c_lieur
			IF @v_charindex <> 0
			BEGIN
				SELECT @v_filtre1 = SUBSTRING(@v_sql, 1, @v_charindex)
				SELECT @v_filtre2 = SUBSTRING(@v_sql, @v_charindex + LEN(@v_lir_libelle) + 2, LEN(@v_sql) - @v_charindex - LEN(@v_lir_libelle))
			END
			IF SUBSTRING(@v_filtre1, 1, 2) = '(('
			BEGIN
				SELECT @v_lcn_idsslstcondition = CASE SIGN(MIN(ARC_IDLSTCONDITION)) WHEN -1 THEN MIN(ARC_IDLSTCONDITION) - 1 ELSE -1 END FROM ASSOCIATION_REGLE_CONDITION
				INSERT INTO ASSOCIATION_REGLE_CONDITION (ARC_IDLSTCONDITION, ARC_IDREGLE, ARC_TYPE, ARC_SYSTEME) VALUES (@v_lcn_idsslstcondition, @v_reg_idregle, 0, 0)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO LISTE_CONDITION (LCN_IDLSTCONDITION, LCN_POSITION, LCN_TYPEITEM, LCN_IDSSLSTCONDITION, LCN_SYSTEME)
						VALUES (@v_arc_idlstcondition, 1, 1, @v_lcn_idsslstcondition, 0)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						EXEC @v_error = CFG_REGLECONDITION 2, @v_reg_idregle, @v_lan_id, @v_filtre1 out, @v_lcn_idsslstcondition, 0, @v_retour out
				END
			END
			ELSE
				EXEC @v_error = CFG_REGLECONDITION 2, @v_reg_idregle, @v_lan_id, @v_filtre1 out, @v_arc_idlstcondition, 1, @v_retour out
			IF ((@v_retour = 113) AND (@v_error = 0))
			BEGIN
				IF SUBSTRING(@v_filtre2, 1, 2) = '(('
				BEGIN
					SELECT @v_lcn_idsslstcondition = CASE SIGN(MIN(ARC_IDLSTCONDITION)) WHEN -1 THEN MIN(ARC_IDLSTCONDITION) - 1 ELSE -1 END FROM ASSOCIATION_REGLE_CONDITION
					INSERT INTO ASSOCIATION_REGLE_CONDITION (ARC_IDLSTCONDITION, ARC_IDREGLE, ARC_TYPE, ARC_SYSTEME) VALUES (@v_lcn_idsslstcondition, @v_reg_idregle, 0, 0)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO LISTE_CONDITION (LCN_IDLSTCONDITION, LCN_POSITION, LCN_TYPEITEM, LCN_IDSSLSTCONDITION, LCN_IDLIEUR, LCN_SYSTEME)
							VALUES (@v_arc_idlstcondition, 2, 1, @v_lcn_idsslstcondition, @v_lir_idlieur, 0)
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							EXEC @v_error = CFG_REGLECONDITION 2, @v_reg_idregle, @v_lan_id, @v_filtre2 out, @v_lcn_idsslstcondition, 0, @v_retour out
					END
				END
				ELSE
				BEGIN
					EXEC @v_error = CFG_REGLECONDITION 2, @v_reg_idregle, @v_lan_id, @v_filtre2 out, @v_arc_idlstcondition, 2, @v_retour out
					IF ((@v_retour = 113) AND (@v_error = 0))
						UPDATE LISTE_CONDITION SET LCN_IDLIEUR = @v_lir_idlieur WHERE LCN_IDLSTCONDITION = @v_arc_idlstcondition AND LCN_POSITION = 2
				END
			END
		END
		ELSE
			SELECT @v_retour = 116
	END
	RETURN @v_error

