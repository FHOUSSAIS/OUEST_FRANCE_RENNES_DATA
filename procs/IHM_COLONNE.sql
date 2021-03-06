SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: IHM_TABLEAU
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Gestion des colonnes des tableaux
--                                        -> Recuperation des colonnes ordonnees d un tableau : ces colonnes sont stockees dans une table temporaire Tmp
--                                        -> Champs recuperes : ID_COLONNE, ORDRE, TAILLE, CLASSEMENT, SENS, LIBELLE
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_COLONNE]
	@v_uti_id varchar(16),
	@v_vue_id int,
	@v_uti_langue varchar(3),
	@v_order_by varchar(8000) out,
	@v_id_prem_col_triee varchar(32) out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_id_col varchar(32),
	@v_sen_libelle varchar(10),
	@i int

	SET @v_id_prem_col_triee = ''

	CREATE TABLE #Tmp (ID_COLONNE varchar(32), ORDRE tinyint, TAILLE int, CLASSEMENT tinyint, SENS tinyint, FIXE bit, LIBELLE varchar(7000))

	IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLONNE_UTILISATEUR WHERE ACU_UTILISATEUR = @v_uti_id AND ACU_TABLEAU = @v_vue_id)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_COLONNE_GROUPE, ASSOCIATION_UTILISATEUR_GROUPE 
                                                               WHERE ACG_GROUPE = AUG_GROUPE AND AUG_UTILISATEUR = @v_uti_id AND ACG_TABLEAU = @v_vue_id)
		BEGIN --Cas : pas d association vue_tableau utilisateur ni groupe => on recupere les couleurs par defaut ie directement dans vue tableau
			INSERT INTO #Tmp (ID_COLONNE, ORDRE, TAILLE, CLASSEMENT, SENS, FIXE, LIBELLE)
			SELECT DISTINCT COL_ID, COL_ORDRE, COL_TAILLE, COL_CLASSEMENT, COL_SENS, COL_FIXE, LIB_LIBELLE
                                        FROM COLONNE, LIBELLE
				WHERE COL_TABLEAU = @v_vue_id
				      AND COL_VISIBLE = 1
                                                           -- Recuperation du libelle
                                                           AND COL_TRADUCTION = LIB_TRADUCTION
                                                           AND LIB_LANGUE = @v_uti_langue
		END
		ELSE --Cas : un enregistrement association colonne groupe existe
		BEGIN
			INSERT INTO #Tmp (ID_COLONNE, ORDRE, TAILLE, CLASSEMENT, SENS, FIXE, LIBELLE)
			SELECT DISTINCT ACG_COLONNE, COL_ORDRE, COL_TAILLE, COL_CLASSEMENT,  COL_SENS, COL_FIXE, LIB_LIBELLE
                                        FROM ASSOCIATION_COLONNE_GROUPE, COLONNE, ASSOCIATION_UTILISATEUR_GROUPE, LIBELLE
                                                WHERE AUG_UTILISATEUR = @v_uti_id 
                                                      AND ACG_GROUPE = AUG_GROUPE
                                                      AND ACG_TABLEAU = @v_vue_id
                                                     -- Recuperation du libelle
                                                      AND COL_TABLEAU = ACG_TABLEAU
                                                      AND COL_ID = ACG_COLONNE
                                                      AND COL_TRADUCTION = LIB_TRADUCTION
                                                      AND LIB_LANGUE = @v_uti_langue
		END
	END
	ELSE --Cas : un enregistrement association colonne utilisateur existe*/
	BEGIN
		INSERT INTO #Tmp (ID_COLONNE, ORDRE, TAILLE, CLASSEMENT, SENS, FIXE, LIBELLE)
		SELECT ACU_COLONNE, ACU_ORDRE, ACU_TAILLE, ACU_CLASSEMENT, ACU_SENS, COL_FIXE, LIB_LIBELLE
		FROM ASSOCIATION_COLONNE_UTILISATEUR, COLONNE, LIBELLE
			WHERE ACU_UTILISATEUR = @v_uti_id 
                                              AND ACU_TABLEAU = @v_vue_id
                                              -- Recuperation du libelle
                                              AND COL_TABLEAU = ACU_TABLEAU
                                              AND COL_ID = ACU_COLONNE
                                              AND COL_TRADUCTION = LIB_TRADUCTION
                                              AND LIB_LANGUE = @v_uti_langue
	END

	--Construction de la chaine de caracteres de l ORDER BY
	DECLARE cur_colonne CURSOR LOCAL FOR SELECT ID_COLONNE, SEN_LIBELLE FROM #Tmp, SENS
	WHERE SEN_IDSENS = SENS
	ORDER BY CLASSEMENT
	OPEN cur_colonne
	FETCH NEXT FROM cur_colonne INTO @v_id_col,  @v_sen_libelle
	IF @@FETCH_STATUS = 0
	BEGIN
		SET @v_order_by = 'ORDER BY '
		SET @i = 0
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @i = 0
				SET @v_id_prem_col_triee = @v_id_col
			SET @i = @i + 1
			SET @v_order_by = @v_order_by + @v_id_col + ' ' + @v_sen_libelle + ', '			FETCH NEXT FROM cur_colonne INTO @v_id_col, @v_sen_libelle
		END
	END
	CLOSE cur_colonne
	DEALLOCATE cur_colonne
	SELECT @v_order_by = SUBSTRING(@v_order_by, 1, LEN(@v_order_by) - 1)

	SELECT ID_COLONNE, ORDRE, TAILLE, CLASSEMENT, SENS, FIXE, LIBELLE FROM #Tmp ORDER BY FIXE DESC, ORDRE
	DROP TABLE #Tmp



