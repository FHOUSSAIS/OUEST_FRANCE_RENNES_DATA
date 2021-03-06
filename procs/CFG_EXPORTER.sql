SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_EXPORTER
-- Paramètre d'entrées	: @v_type : Type
--				0 : Configuration sans gestion de profil, d'énergie, la planification
--				des modes d'exploitations et la configuration des analyseurs
--				1 : Configuration complète
-- Paramètre de sorties	: 
-- Descriptif		: Exportation de la configuration
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_EXPORTER]
	@v_type bit = 0
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_commande varchar(8000),
	@v_sql varchar(8000),
	@v_base sysname,
	@v_table sysname,
	@v_identity bit,
	@v_column_name varchar(128),
	@v_column_type varchar(128),
	@v_column_list varchar(8000),
	@v_value_list varchar(8000),
	@v_reference sysname

	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL ON
	CREATE TABLE #RESULT (IDENTIFIANT int identity (1, 1), SQL varchar(8000))
	CREATE TABLE #TABLE (TABLE_NAME sysname, ORDRE int identity (1, 1), ISIDENTITY bit, TYPE tinyint)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_BASE_REGION', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('REGION', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_PORTE_SAS', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SAS', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_INFO_AGV_PORTE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('PORTE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTEGRATION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('EMBALLAGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('GABARIT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_SYMBOLE_ITEM', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ITEM', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('AFFICHAGE_CHARGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('PARAMETRE_VARIABLE_CIRCUIT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VARIABLE_CIRCUIT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SOUS_MENU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('MENU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONFIG_RSV_ENERGIE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONFIG_EVT_ENERGIE', 1, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONFIG_OBJ_ENERGIE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_EVT_ENERGIE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COULEUR', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VOYANT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ECHANGE_LS', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_BDD_LS', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ECHANGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SEGMENT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONNEXION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_SOCKET_TCPIP', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_ROUTEUR_IHM', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_HORLOGE_THREAD', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_FICHIER_API', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VARIABLE_AUTOMATE_OPC', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_AUTOMATE_OPC', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VARIABLE_AUTOMATE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ENTREE_SORTIE_OPC', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ENTREE_SORTIE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_TERMINAL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_CAB_VALUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_SAISIE_VALUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_AUTOMATE_TERMINAL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_TRANSITION_AUTOMATE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_ETAT_AUTOMATE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_FONCTION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_ASSOCIATION_VOYANT_ECRAN', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_CMD_BUZZER', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_CMD_VOYANT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_ASSOCIATION_MESSAGE_ECRAN', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_ECRAN', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_CODE_A_BARRES', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_SAISIE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_MESSAGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_PARAMETRE_TRAITEMENT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_TRAITEMENT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_TYPE_AUTOMATE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OSYS_TYPE_FONCTION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_ES_OPC', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_PILOTAGE_UDP', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_OSYS', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERFACE_PHYSIQUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COMPATIBILITE_INTERFACE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_TYPE_INTERFACE_MESSAGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_INTERFACE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ABONNEMENT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ABONNE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('MESSAGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OUTIL_AGV', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('PLANIFICATION', 1, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INFO_AGV', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DEFAUT_AGV', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DEFAUT_SPV', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_AGV', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_OUTIL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('MODE_EXPLOITATION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('LISTE_CONDITION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_REGLE_CONDITION', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONDITION', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_REGLE_TRI', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TRI', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CRITERE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VARIABLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COMBINAISON_DE_REGLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COMBINAISON', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('JEU_REGLE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONTEXTE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('REGLE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ACTION_REGLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_ACTION_REGLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INFORMATION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SAISIE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('GRAPHIQUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CLASSE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SPECIFIQUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_COLORIAGE_UTILISATEUR', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_COLORIAGE_GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COLORIAGE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VALEUR', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_FILTRE_UTILISATEUR', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('FILTRE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_COLONNE_UTILISATEUR', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_COLONNE_GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COLONNE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TABLEAU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_VUE_UTILISATEUR', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_VUE_GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_VUE_TABLEAU_UTILISATEUR', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_VUE_TABLEAU_GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_UTILISATEUR_GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('POSTE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('UTILISATEUR', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_OPERATION_GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ENTREE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_CATEGORIE_SOUS_MENU_CONTEXTUEL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_SOUS_MENU_CONTEXTUEL_MENU_CONTEXTUEL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SOUS_MENU_CONTEXTUEL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OPERATION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VUE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DLL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TRAITEMENT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('GROUPE', 0, 0)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VUE_SAISIE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VUE_GRAPHIQUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VUE_SPECIFIQUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('VUE_TABLEAU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_VUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_OPERATION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CHAMP', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DONNEE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('COMPOSANT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('FLUX', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_ZONE_JEU_ZONE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('JEU_ZONE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ZONE_CONTENU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ZONE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('STRUCTURE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ADRESSE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('BASE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_SYMBOLE_IMAGE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('IMAGE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_SYMBOLE_TEXTE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TEXTE', 1, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_CONTENU_LEGENDE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_CATEGORIE_CONTENU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CONTENU', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('LEGENDE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('MENU_CONTEXTUEL', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ASSOCIATION_CATEGORIE_SYMBOLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SYMBOLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('PROPRIETE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CATEGORIE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_VARIABLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ATTRIBUT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SYSTEME', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SECTEUR', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SITE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CLIENT', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('PARAMETRE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('LIBELLE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('LANGUE', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TRADUCTION', 0, 1)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('BATTERIE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('INTERACTION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('RESERVATION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('PRODUIT', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('EVT_ENERGIE_EN_COURS', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('MISSION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CRITERE_MISSION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CRITERE_ZONE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('CHARGE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TACHE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OCCUPATION_ZONE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_MISSION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_MISSION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_TACHE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_ORDRE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_AGV', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DESC_ETAT_ACTION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DESC_ETAT_ORDRE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('DESC_ETAT_TACHE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_ACTION_TACHE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ACTION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OBJET_JDB_MISSION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OBJET_JDB_ORDRE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OBJET_JDB_EXPLOITATION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OBJET_JDB_ATTRIBUTION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OBJET_JDB_ZONE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_EVT_ENERGIE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('FAMILLE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_OBJ_ENERGIE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_MAGASIN', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('TYPE_TRACE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_ZONE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OPERATEUR', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('ETAT_ACTION', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('SYNOPTIQUE', -1, 2)
	INSERT INTO #TABLE (TABLE_NAME, ISIDENTITY, TYPE) VALUES ('OPTION_ACTION', -1, 2)
	DECLARE c_table CURSOR LOCAL FOR SELECT TABLE_NAME FROM #TABLE WHERE (@v_type = 0 AND TYPE = 0) OR TYPE = 2
	OPEN c_table
	FETCH NEXT FROM c_table INTO @v_table
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE c_reference CURSOR LOCAL FOR SELECT name FROM sysobjects WHERE parent_obj = (SELECT id FROM sysobjects WHERE name = @v_table)
			AND xtype = 'F'
		OPEN c_reference
		FETCH NEXT FROM c_reference INTO @v_reference
		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO #RESULT (SQL) VALUES ('ALTER TABLE ' + @v_table + ' NOCHECK CONSTRAINT ' + @v_reference + ';')
			FETCH NEXT FROM c_reference INTO @v_reference
		END
		FETCH NEXT FROM c_table INTO @v_table
		CLOSE c_reference
		DEALLOCATE c_reference
	END
	CLOSE c_table
	DEALLOCATE c_table
	DECLARE c_table CURSOR LOCAL FOR SELECT TABLE_NAME FROM #TABLE WHERE (@v_type = 0 AND TYPE = 1)  OR (@v_type = 1 AND TYPE IN (0, 1)) ORDER BY ORDRE
	OPEN c_table
	FETCH NEXT FROM c_table INTO @v_table
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO #RESULT (SQL) VALUES ('DELETE ' + @v_table + ';')
		FETCH NEXT FROM c_table INTO @v_table
	END
	CLOSE c_table
	DEALLOCATE c_table
	SET NOCOUNT ON
	DECLARE c_table CURSOR LOCAL FOR SELECT TABLE_NAME, ISIDENTITY FROM #TABLE WHERE (@v_type = 0 AND TYPE = 1)  OR (@v_type = 1 AND TYPE IN (0, 1)) ORDER BY ORDRE DESC
	OPEN c_table
	FETCH NEXT FROM c_table INTO @v_table, @v_identity
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @v_identity = 1
			INSERT INTO #RESULT (SQL) VALUES ('SET IDENTITY_INSERT ' + @v_table + ' ON;')
		SELECT @v_sql = 'INSERT INTO ' + @v_table + ' '
		SELECT @v_column_list = '('
		SELECT @v_value_list = 'VALUES ('
		DECLARE c_column CURSOR LOCAL FOR SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = @v_table ORDER BY ORDINAL_POSITION
		OPEN c_column
		FETCH NEXT FROM c_column INTO @v_column_name, @v_column_type
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF COLUMNPROPERTY(OBJECT_ID(@v_table), @v_column_name, 'IsComputed') <> 1
			BEGIN
				SELECT @v_column_list = @v_column_list + @v_column_name + ', '
				SELECT @v_value_list = @v_value_list +
				CASE
					WHEN @v_column_type IN ('char', 'varchar') THEN ''' + COALESCE('''''''' + REPLACE(' + @v_column_name + ', '''''''', '''''''''''') + '''''''', ''NULL'')'
					WHEN @v_column_type = ('datetime') THEN ''' + COALESCE('''''''' + RTRIM(CONVERT(char, ' + @v_column_name + ', 109)) + '''''''', ''NULL'')'
					ELSE ''' + COALESCE(CONVERT(varchar, ' +  @v_column_name + '), ''NULL'')'
				END + ' + '', '
			END
			FETCH NEXT FROM c_column INTO @v_column_name, @v_column_type
		END
		CLOSE c_column
		DEALLOCATE c_column
		SELECT @v_column_list = LEFT(@v_column_list, LEN(@v_column_list) - 1) + ')'
		SELECT @v_value_list = LEFT(@v_value_list, LEN(@v_value_list) - 2) + ''');'
		SELECT @v_sql = @v_sql + @v_column_list + ' ' + @v_value_list
		SELECT @v_commande = 'SELECT ''' + @v_sql + ''' FROM ' + @v_table
		INSERT INTO #RESULT (SQL) EXEC (@v_commande)
		IF @v_identity = 1
			INSERT INTO #RESULT (SQL) VALUES ('SET IDENTITY_INSERT ' + @v_table + ' OFF;')
		FETCH NEXT FROM c_table INTO @v_table, @v_identity
	END
	CLOSE c_table
	DEALLOCATE c_table
	DECLARE c_table CURSOR LOCAL FOR SELECT TABLE_NAME FROM #TABLE WHERE (@v_type = 0 AND TYPE = 0) OR TYPE = 2
	OPEN c_table
	FETCH NEXT FROM c_table INTO @v_table
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE c_reference CURSOR LOCAL FOR SELECT name FROM sysobjects WHERE parent_obj = (SELECT id FROM sysobjects WHERE name = @v_table)
			AND xtype = 'F'
		OPEN c_reference
		FETCH NEXT FROM c_reference INTO @v_reference
		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO #RESULT (SQL) VALUES ('ALTER TABLE ' + @v_table + ' CHECK CONSTRAINT ' + @v_reference + ';')
			FETCH NEXT FROM c_reference INTO @v_reference
		END
		FETCH NEXT FROM c_table INTO @v_table
		CLOSE c_reference
		DEALLOCATE c_reference
	END
	CLOSE c_table
	DEALLOCATE c_table
	DROP TABLE #TABLE
	SELECT SQL FROM #RESULT ORDER BY IDENTIFIANT
	DROP TABLE #RESULT

